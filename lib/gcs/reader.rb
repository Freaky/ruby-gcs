
require_relative 'bitio'

module GCS
  class Reader
    attr_reader :n
    attr_reader :p

    module Index
      class OnDisk
        RECORDSIZE = 16

        attr_reader :length

        def initialize(io, start, length)
          @io = io
          @start = start
          @length = length
        end

        def lookup(key)
          low = 0
          high = @length # -1 ?
          midkey = midval = mid = 0

          while low <= high
            mid = (low + high) / 2

            # Replace with pread
            @io.seek(@start + (mid * RECORDSIZE))
            midkey, midval = @io.read(RECORDSIZE).unpack('Q>2')

            if midkey < key
              low = mid + 1
            elsif midkey > key
              high = mid - 1
            else
              break
            end
          end

          @io.seek([@start + (mid * RECORDSIZE) - RECORDSIZE, @start].max)
          return @io.read(RECORDSIZE).unpack('Q>2')
        end
      end

      class InMemory
        attr_reader :length

        def initialize(io, start, length)
          @length = length
          io.seek(start)
          @index = [[0,0]]
          @index += Array.new(length) do
            io.read(16).unpack('Q>2')
          end
        end

        def lookup(key)
          idx = @index.bsearch_index { |x| x[0] > key }
          if idx
            @index[idx == 0 ? 0 : idx - 1]
          else
            @index.last
          end
        end

       def inspect
         "#<#{self.class}:0x#{self.object_id.to_s(16)} start=#{@start} length=#{@length}>"
       end
      end
    end

    def initialize(io)
      io.seek(-40, IO::SEEK_END)
      footer = io.read(40)
      if footer[-8, 8] != GCS_MAGIC
        raise ArgumentError, "Not a GCS file"
      end

      @n, @p, @end_of_data, @index_len = footer.unpack('Q>4')
      @log2p = Math.log2(@p).ceil

      indeximpl = case @index_len
      when 0..1024 then Index::InMemory
      else              Index::OnDisk
      end

      @index = indeximpl.new(io, @end_of_data, @index_len)

      @io = BitIO::Reader.new(io)
    end

    def exists?(key)
      h = key % (@n * @p)

      last = pos = 0

      if lp = @index.lookup(h)
        last, pos = lp
      end

      @io.seek(pos)

      while last < h
        diff = 0
        while @io.read_bit == 1
          diff += @p
        end

        diff += @io.read_bits(@log2p)
        last += diff

        break if diff.zero?
      end

      last == h
    end
  end
end
