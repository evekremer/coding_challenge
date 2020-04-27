module Memcached
    class StorageCommand < Server
        include Util
        PARAMETERS_MAX_LENGTH = 5

        def initialize(command_name, parameters, connection, parameters_max_length = PARAMETERS_MAX_LENGTH)
            @conn = connection
            @cmd_name = command_name

            # max_length: number of maximum parameters expected (excluding command name)
            @parameters_max_length = parameters_max_length
            validate_number_of_parameters!(parameters)
            
            @key, @flags, exptime, @length = parameters
            validate_key!(key)
            validate_flags!(flags)

            @expdate = expiration_date(exptime)
            @data_block = request_data_block_handler
            @no_reply = has_no_reply?(parameters)
        end

        def key
            @key
        end

        def flags
            @flags
        end

        def expdate
            @expdate
        end

        def length
            @length
        end

        def data_block
            @data_block
        end

        def command_name
            @cmd_name
        end

        def no_reply
            @no_reply
        end

        def store_new_item
            # Determine the length added by the new insertion to the total length stored
            # If the key is already stored, the added length is the length of the new item minus the previously stored length
            added_length = length.to_i - cache.length(key)
            new_item = Memcached::Item.new(flags, expdate, data_block)

            cache.store_item(key, new_item, added_length)
            message = STORED_MSG
        end

        private

        def parameters_max_length
            @parameters_max_length
        end

        # Determine the expiration date corresponding to the <exptime> parameter received
        def expiration_date(exptime)
            validate_exptime!(exptime)

            expt = exptime.to_i
            case
            when expt == 0 # Never expires 
                expdate = 0
            when expt < 0 # Immediately expired
                expdate = Time.now
            when expt <= 30 * SECONDS_PER_DAY
                expdate = Time.now + expt # Offset from current time
            else
                expdate = UNIX_TIME + expt # Offset from 1/1/1970 (Unix time)
            end
            expdate
        end

        def request_data_block_handler
            validate_length!(length)

            data_block = ""
            while line = @conn.gets
                data_block += line
                break if data_block.length() >= (length.to_i + 2)
            end

            validate_command_termination!(data_block)
            validate_data_block_max_length!(data_block)
            validate_length_data!(length, data_block)
        end

        # Determine if the optional "noreply" parameter is included in command
        def has_no_reply?(parameters)
            no_reply = false
            if parameters.length() == @parameters_max_length
                validate_no_reply_syntax!(parameters)
                no_reply = true
            end
            no_reply
        end

        def validate_number_of_parameters!(parameters)
            validate_parameters_min_length!(parameters, parameters_max_length-1)
            validate_parameters_max_length!(parameters, parameters_max_length)
        end

        def validate_parameters_max_length!(parameters)
            raise ArgumentClientError, TOO_MANY_ARGUMENTS unless parameters.length() <= parameters_max_length
        end

        def validate_no_reply_syntax!(parameters)
            raise ArgumentClientError, "\"#{NO_REPLY_PARAMETER}\" was expected as the #{parameters_max_length+1}th argument, but \"#{parameters[parameters_max_length-1]}\" was received" unless parameters[parameters_max_length-1] == NO_REPLY_PARAMETER
        end
    end
end