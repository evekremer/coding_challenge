module Memcached
  class Item
    def initialize(flags, expdate, length, data_block, cas_key)
      @flags = flags.to_s
      @expdate = expdate
      @data_block = data_block.to_s
      @cas_key = cas_key.to_s
      @length = length.to_s

      validate!
    end

    def cas_key=(cas_key)
      @cas_key = cas_key
    end

    def cas_key
      @cas_key
    end

    def data_block=(data_block)
      @data_block = data_block.to_s
    end

    def data_block
      @data_block
    end

    def flags
      @flags
    end

    def length=(length)
      @length = length.to_s
    end

    def length
      @length
    end

    def is_expired?
      self.expdate.to_i != 0 && Time.now >= self.expdate
    end

    private

    def validate!
      raise TypeError unless @expdate.is_a?(Date)
    end
  end
end