module Memcached
    STORED_MSG = "STORED\r\n"
    NOT_STORED_MSG = "NOT_STORED\r\n"
    NOT_FOUND_MSG = "NOT_FOUND\r\n"
    EXISTS_MSG = "EXISTS\r\n"
    INVALID_COMMAND_NAME_MSG = "ERROR\r\n"
    END_MSG = "END\r\n"

    # Expiration date
    SECONDS_PER_DAY = 60*60*24
    UNIX_TIME = Time.new(1970,1,1)
    
    ONE_MEGABYTE = (2 ** 20)
    MAX_KEY_LENGTH = 250
    MAX_DATA_BLOCK_LENGTH = ONE_MEGABYTE # 1MB
    MAX_CAS_KEY = (2 ** 64) - 1 # 64-bit unsigned int
    MAX_CACHE_CAPACITY = 64 * ONE_MEGABYTE # 64MB

    class ArgumentClientError < StandardError; end
    class TypeClientError < StandardError; end

    class Util
        def validate_termination(command)
            command_ending = command[-2..-1] || command
            raise ArgumentClientError, "Commands must be terminated by '\r\n'" unless command_ending == "\r\n"
            command[0..-3] || command
        end

        def validate_parameters(parameters)
            parameters.each do |p|
                case p[0]
                when "key"
                    raise TypeClientError, '<key> must be provided' unless p[1] != ""
                    raise TypeClientError, '<key> must not include control characters' unless !(/\x00|[\cA-\cZ]/ =~ p[1])
                    raise TypeClientError, "<key> has more than #{MAX_KEY_LENGTH} characters" unless p[1].length() <= MAX_KEY_LENGTH
                when "length"
                    raise TypeClientError, '<length> is not an unsigned integer' unless is_unsigned_i(p[1])
                    raise ArgumentClientError, "<length> (#{p[1]}) is not equal to the length of the item's data_block (#{p[2]})" unless p[2] == p[1].to_i
                when "flags"
                    raise TypeClientError, '<flags> is not a 16-bit unsigned integer' unless is_unsigned_i(p[1], 16)
                when "exptime"
                    raise TypeClientError, '<exptime> is not an integer' unless /\A[-+]?\d+\z/ === p[1]
                when "data_block"
                    raise TypeClientError, "<data_block> has more than #{MAX_DATA_BLOCK_LENGTH} characters" unless p[1] <= MAX_DATA_BLOCK_LENGTH
                end
            end
        end

        def has_no_reply(command_split, max_length)
            raise ArgumentClientError, "The command has too many arguments" unless command_split.length() <= max_length
            raise ArgumentClientError, "The command has too few arguments" unless command_split.length() >= max_length-1

            no_reply = false
            if command_split.length() == max_length
                if command_split[max_length-1] == "noreply"
                    no_reply = true
                else # incorrect syntax
                    raise ArgumentClientError, "A 'noreply' was expected as the #{max_length+1}th argument, but '#{command_split[max_length-1]}' was received"
                end
            end
            no_reply
        end

        def expiration_date(exptime)
            case
            when exptime == 0 # Never expires 
                expdate = 0
            when exptime < 0 # Immediately expired
                expdate = Time.now
            when exptime <= 30 * SECONDS_PER_DAY
                expdate = Time.now + exptime # Offset from current time
            else
                expdate = UNIX_TIME + exptime # Offset from 1/1/1970 (Unix time)
            end
            expdate
        end

        def is_unsigned_i(data, num_bits = nil)
            /\A\d+\z/ === data && (num_bits ? data.to_i < 2**num_bits && data.to_i >= 0 : true )
        end
    end
end