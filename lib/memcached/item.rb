module Memcached
    class Item
        include Util

        def initialize(flags, expdate, length, data_block, cas_key = "")
            @flags = flags
            @expdate = expdate
            @data_block = data_block
            @cas_key = cas_key

            validate!
        end

        def cas_key=(cas_key)
            @cas_key = cas_key
        end

        def cas_key
            @cas_key
        end

        def data_block=(data_block)
            validate_db_type!
            @data_block = data_block
        end

        def data_block
            @data_block
        end

        def flags
            @flags
        end

        def length 
            @data_block.length()
        end

        def is_expired?
            self.expdate.to_i != 0 && Time.now >= self.expdate
        end

        private

        def validate_db_type!
            raise TypeError unless data_block.is_a?(String)
        end

        def validate!
            validate_db_type!(data_block)
            raise TypeError unless @expdate.is_a?(Date)
            raise TypeError unless @flags.is_a?(String)
            raise TypeError unless @cas_key.is_a?(String)
        end
    end
end