require 'socket'

module Memcached
    class Server
        # Response messages
        STORED_MSG = "STORED\r\n"
        NOT_STORED_MSG = "NOT_STORED\r\n"
        NOT_FOUND_MSG = "NOT_FOUND\r\n"
        EXISTS_MSG = "EXISTS\r\n"
        INVALID_COMMAND_NAME_MSG = "ERROR\r\n"
        END_MSG = "END\r\n"

        # Expiration date
        SECONDS_PER_DAY = 60*60*24
        UNIX_TIME = Time.new(1970,1,1)

        MAX_KEY_LENGTH = 250
        MAX_VALUE_LENGTH = (2 ** 20) - 1 # 1MB
        MAX_CAS_KEY = (2 ** 64) - 1 # 64-bit unsigned int
        MAX_CACHE_ITEMS = 64

        def initialize(socket_address, socket_port)
            @server_socket = TCPServer.open(socket_address, socket_port)
            # @connections_details = Hash.new
            # @connections_details[:server] = @server_socket
            @cache = Hash.new
            @mutex_readers = Mutex.new
            @mutex_writers = Mutex.new
            @readers_counter = 0
            @unique_cas_key = 0

            puts 'The server has been started'
            establish_connections
        end

        def establish_connections
            loop{
                client_connection = @server_socket.accept
                Thread.start(client_connection) do |conn|
                    puts "Connection established => #{conn}"
                    request_handler(conn)
                    puts "Connection closed => #{conn}"
                end
            }.join
            @server_socket.close
        end

        def request_handler(connection)
            begin
                loop do
                    command = connection.gets
                    command_ending = command[-2..-1] || command
                    raise ArgumentError, "Commands must be terminated by \r\n" unless command_ending == "\r\n"

                    command = command.delete "\r\n"
                    command_split = command.split(/ /)
                    command_name = command_split.shift

                    if ["set", "add", "replace", "prepend", "append", "cas"].include? command_name
                        key, flags, exptime, length = command_split
                        
                        if is_unsigned_i(length)
                            data_block = connection.read(length.to_i)
                            connection.gets
                        else
                            connection.gets
                            raise TypeError, '<length> is not an unsigned integer'
                        end

                        raise ArgumentError, "<length> (#{length}) is not equal to the length of the item's value (#{data_block.length()})" unless data_block.length() == length.to_i
                        
                        # Check if the optional 'noreply' parameter is included
                        max_length = (command_name == "cas" ? 6 : 5)
                        no_reply = has_no_reply(command_split, max_length)
                    end

                    case command_name
                    when "set"
                        store_new_item(key, flags, exptime, length, data_block)
                        message = STORED_MSG

                    when "add", "replace" # [Add / Replace]: store item if the key [does / does not] exist
                        # Read shared cache
                        start_reading
                        cache_has_key = @cache.has_key?(key)
                        finish_reading

                        if (!cache_has_key && command_name == "add") || (cache_has_key && command_name == "replace")
                            store_new_item(key, flags, exptime, length, data_block)
                            message = STORED_MSG
                        else
                            message = NOT_STORED_MSG
                        end

                    when "prepend", "append"
                        message = pre_append(key, length, data_block, command_name == "prepend")

                    when "cas"
                        message = cas(key, flags, exptime, length, command_split[4], data_block)

                    when "get", "gets"
                        message = retrieve_items(command_split, command_name == "gets")
                    
                    when "quit" # Terminate session
                        break
                    
                    else 
                        message = INVALID_COMMAND_NAME_MSG
                    end

                    if !no_reply
                        connection.puts message
                    end
                end
                connection.close # Disconnect from the client
            rescue ArgumentError, TypeError => e
                connection.puts "CLIENT_ERROR #{e.message}\r\n" # the input doesn't conform to the protocol
                request_handler(connection)
            end
        end

        # Check and set (cas): set the data if it is not updated since last fetch
        def cas(key, flags, exptime, length, unique_cas_key, value)
            raise TypeError, '<cas_unique> is not a 64-bit unsigned integer' unless is_unsigned_i(unique_cas_key, 64)
            
            # Read shared cache
            start_reading
            cache_has_key = @cache.has_key?(key)
            if cache_has_key
                equal_unique_cas_key = @cache[key][4] == unique_cas_key.to_i
            end
            finish_reading

            if !cache_has_key # The key does not exist in the cache
                message = NOT_FOUND_MSG
            elsif !equal_unique_cas_key # The item has been modified since last fetch
                message = EXISTS_MSG
            else
                store_new_item(key, flags, exptime, length, value)
                message = STORED_MSG
            end
            message
        end
        
        # [Prepend / Append]: adds 'value' to an existing key [before / after] existing value
        def pre_append(key, length, value, pre = false)
            validate_parameters([ ["length", length, value.length()] ])

            # Read shared cache
            start_reading
            cache_has_key = @cache.has_key?(key)
            if @cache.has_key?(key)
                prev_length = @cache[key][2]
            end
            finish_reading

            validate_parameters([ ["value", value.length() + prev_length.to_i] ])

            if cache_has_key # the key exists in the Memcached server          
                @mutex_writers.lock()
                    # Write shared cache
                    @cache[key][2] = @cache[key][2].to_i + length.to_i # Add 'length' to the previous length
                    @cache[key][3] = ( pre ? value.concat(@cache[key][3]) : @cache[key][3].concat(value))
                    @cache[key][4] = @unique_cas_key # Update cas key
                    update_cas_key
                @mutex_writers.unlock()
                message = STORED_MSG
            else
                message = NOT_STORED_MSG
            end
            message
        end
        
        # Retrieves the value stored at 'keys'. Keys that do not exists do not appear on the response
        def retrieve_items(keys, gets = false)
            raise ArgumentError, '<key>* must be provided' unless keys != []

            reply = ""
            keys.each do |key|
                validate_parameters([["key", key]])

                # Read shared cache
                start_reading
                cache_has_key = @cache.has_key?(key)
                if cache_has_key
                    flags, expdate, length, value, unique_cas_key = @cache[key]
                end
                finish_reading

                #Delete from cache if the item is expired
                if expdate.to_i != 0 && Time.now >= expdate             
                    @mutex_writers.lock()
                        # Write shared cache
                        @cache.delete(key)
                    @mutex_writers.unlock()
                
                elsif cache_has_key
                    reply += "VALUE #{key} #{flags} #{length}"
                    reply += gets ? " #{unique_cas_key}" : ""
                    reply += "\r\n#{value}\r\n"
                end
            end
            reply += END_MSG
            reply 
        end

        def store_new_item(key, flags, exptime, length, value)
            validate_parameters([["key", key], ["flags", flags], ["exptime", exptime], ["length", length, value.length()], ["value", value.length()] ])

            #Calculate the expiration date from the given exptime
            if exptime.to_i == 0 # Never expires 
                expdate = 0
            elsif exptime.to_i < 0 # Immediately expired
                expdate = Time.now
            elsif exptime.to_i <= 30 * SECONDS_PER_DAY
                expdate = Time.now + exptime.to_i # Offset from current time
            else
                expdate = UNIX_TIME + exptime.to_i # Offset from 1/1/1970 (Unix time)
            end
        
            # start_reading
            # if @cache.length + 1 > MAX_CACHE_ITEMS
            #     lru
            # end
            # stop_reading

            @mutex_writers.lock()
                # Write shared cache
                @cache[key] = flags, expdate, length, value, @unique_cas_key
                update_cas_key
            @mutex_writers.unlock()

        end

        private # -------------------------------

        def start_reading
            @mutex_readers.lock()
                @readers_counter += 1
                if(@readers_counter == 1)
                    @mutex_writers.lock()
                end
            @mutex_readers.unlock()
        end

        def finish_reading
            @mutex_readers.lock()
                @readers_counter -= 1
                if(@readers_counter == 0)
                    @mutex_writers.unlock()
                end
            @mutex_readers.unlock()
        end
        
        def update_cas_key
            @unique_cas_key += 1
            # @unique_cas_key = @unique_cas_key % MAX_CAS_KEY
        end

        def validate_parameters(parameters)
            parameters.each do |p|
                case p[0]
                when "key"
                    raise TypeError, '<key> must be provided' unless p[1] != ""
                    raise TypeError, '<key> must not include control characters' unless !has_control_characters(p[1])
                    raise TypeError, "<key> has more than #{MAX_KEY_LENGTH} characters" unless p[1].length() <= MAX_KEY_LENGTH
                when "length"
                    raise TypeError, '<length> is not an unsigned integer' unless is_unsigned_i(p[1])
                    raise ArgumentError, "<length> (#{p[1]}) is not equal to the length of the item's value (#{p[2]})" unless p[2] == p[1].to_i
                when "flags"
                    raise TypeError, '<flags> is not a 16-bit unsigned integer' unless is_unsigned_i(p[1], 16)
                when "exptime"
                    raise TypeError, '<exptime> is not an integer' unless is_i(p[1])
                when "value"
                    raise TypeError, "<value> has more than #{MAX_VALUE_LENGTH} characters" unless p[1] <= MAX_VALUE_LENGTH
                end
            end
        end

        def has_no_reply(command_split, max_length)
            raise ArgumentError, "The command has too many arguments" unless command_split.length() <= max_length
            raise ArgumentError, "The command has too few arguments" unless command_split.length() >= max_length-1

            no_reply = false
            if command_split.length() == max_length-1
                no_reply = false

            elsif command_split.length() == max_length
                if command_split[max_length-1] == "noreply"
                    no_reply = true
                else # incorrect syntax
                    raise ArgumentError, "A 'noreply' was expected as the #{max_length+1}th argument, but #{command_split[max_length-1]} was received"
                end
            end
            no_reply
        end

        def is_i(data)
            /\A[-+]?\d+\z/ === data
        end

        def is_unsigned_i(data, num_bits = nil)
            /\A\d+\z/ === data && (num_bits != nil ? data.to_i < 2**num_bits && data.to_i >= 0 : true )
        end

        def has_control_characters(data)
            /\x00|[\cA-\cZ]/ =~ data
        end

        def lru
        end
    end

    # Socket address and port set from command line arguments
    socket_address = ARGV[0] || "localhost"
    socket_port = ARGV[1] || 9999

    Server.new( socket_address, socket_port )
end