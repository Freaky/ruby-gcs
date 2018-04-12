
require_relative 'bitreader'

module GCS
  GCS_MAGIC = '[GCS:v0]'

  class Reader
    attr_reader :n
    attr_reader :p

    def initialize(io)
      io.seek(-40, IO::SEEK_END)
      footer = io.read(40)
      if footer[-8, 8] != GCS_MAGIC
        raise ArgumentError, "Not a GCS file"
      end

      @n, @p, @end_of_data, @index_len = footer.unpack('Q>4')
      @log2p = Math.log2(@p).ceil

      io.seek(@end_of_data)
      @index = Array.new(@index_len) do
        io.read(16).unpack('Q>2')
      end

      @io = BitReader.new(io)
    end

    def exists?(key)
      h = key % (@n * @p)
      idx = [@index.bsearch_index { |x| x[0] >= h } - 1, 0].max

      last, pos = @index[idx]

      @io.seek(pos)

      while last < h
        while @io.read_bit == 1
          last += @p
        end

        last += @io.read_bits(@log2p)
      end

      last == h
    end
  end
end
