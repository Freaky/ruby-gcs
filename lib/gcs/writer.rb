
require_relative 'bitio'

module GCS
  class GolombEncoder
    def initialize(io, fp)
      @io = BitIO::Writer.new(io)
      @p = fp
      @log2p = Math.log2(@p).ceil
    end

    def encode(val)
      q = val / @p
      r = val % @p

      written = @io.write_bits(q + 1, (1 << (q + 1)) - 2)
      written + @io.write_bits(@log2p, r)
    end

    def finish
      @io.flush
    end
  end

  class Writer
    attr_reader :n
    attr_reader :p

    def initialize(io, fp, index_granularity = 1024)
      @io = io
      @p = fp
      @index_granularity = index_granularity
      @values = []
    end

    def <<(value)
      @values << value
    end

    def finish
      @n = @values.size
      np = @n * @p

      @values.map! {|v| v % np}
      @values.sort!
      @values.uniq!

      index = []
      encoder = GolombEncoder.new(@io, @p)

      bits_written = 0
      last = 0
      diff = 0
      @values.each_with_index do |v, i|
        diff = v - last
        last = v

        bits_written += encoder.encode(diff)

        if @index_granularity > 0 && i > 0 && i % @index_granularity == 0
          index << [v, bits_written]
        end
      end

      bits_written += encoder.encode(0)
      bits_written += encoder.finish

      end_of_data = bits_written / 8

      index.each do |entry|
        @io.write(entry.pack('Q>2'))
      end

      @io.write([@n, @p, end_of_data, index.size].pack('Q>4'))
      @io.write(GCS_MAGIC)
      @io.close
      @values.clear

      true
    end
  end
end
