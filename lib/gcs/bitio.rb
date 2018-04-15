
module BitIO
  MASKS = [
    0, 0b1, 0b11, 0b111, 0b1111, 0b11111, 0b111111, 0b1111111, 0b11111111,
  ].freeze

  class Reader
    def initialize(io)
      @io = io
      reset
    end

    def reset
      @buffer = 0
      @unused = 0
    end

    def read_bits(nbits)
      ret = 0
      rbits = nbits

      while rbits > @unused
        ret |= @buffer << (rbits - @unused)
        rbits -= @unused

        @buffer = @io.readbyte
        @unused = 8
      end

      if rbits > 0
        ret |= @buffer >> (@unused - rbits)
        @buffer &= MASKS[@unused - rbits];
        @unused -= rbits
      end

      ret
    end

    def read_bit
      read_bits(1)
    end

    def seek(bitpos)
      reset
      @io.seek(bitpos / 8)
      read_bits(bitpos % 8)
      true
    end

    alias pos= seek

    def io
      @io
    end
  end

  class Writer
    def initialize(io)
      @io = io
      reset
    end

    def reset
      @buffer = 0
      @unused = 8
    end

    def write_bits(nbits, value)
      nbits_remaining = nbits

      if nbits_remaining >= @unused && @unused < 8
        excess_bits = nbits_remaining - @unused
        @buffer <<= @unused
        @buffer |= (value >> excess_bits) & MASKS[@unused]

        @io.putc(@buffer)

        nbits_remaining = excess_bits
        @unused = 8
        @buffer = 0
      end

      while nbits_remaining >= 8
        nbits_remaining -= 8
        @io.putc((value >> nbits_remaining) & 0xff)
      end

      if nbits_remaining > 0
        @buffer <<= nbits_remaining
        @buffer |= value & MASKS[nbits_remaining]
        @unused -= nbits_remaining
      end

      nbits
    end

    def write_bit(bit)
      write_bits(1, bit)
    end

    def flush
      written = 0
      if @unused != 8
        @io.putc(@buffer << @unused)
        written = @unused
        @unused = 8
      end
      @io.flush
      written
    end

    def io
      @io
    end
  end
end
