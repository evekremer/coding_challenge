require 'io/wait'
module Memcached
    class Server
        def initialize(socket_address, socket_port)
            @server_socket = TCPServer.open(socket_address, socket_port)
            @cache = Hash.new
            @mutex_readers = Mutex.new
            @mutex_writers = Mutex.new
            @readers_counter = 0
            @unique_cas_key = 0
            @total_length_stored = 0
            @util = Memcached::Util.new
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
                    request_line = connection.gets
                    raise EOFError unless request_line # connection.gets called at end of file returns nil

                    command = @util.validate_termination(request_line)
                    command_split = command.split(/ /)
                    command_name = command_split.shift

                    if ["set", "add", "replace", "prepend", "append", "cas"].include? command_name
                        key, flags, exptime, length = command_split

                        # Read request data block
                        data_block = request_data_block_handler(connection, length)

                        # Determine if the optional <noreply> parameter is included in command
                        # In cas commands, the number of maximum parameters excepted is 6; 5 otherwise (excluding command name)
                        no_reply = @util.has_no_reply(command_split, command_name == "cas" ? 6 : 5)
                    end
                    
                    case command_name
                    when "set"
                        store_new_item(key, flags, exptime, length, data_block)
                        message = STORED_MSG
                    when "add", "replace"
                        message = add_replace(key, flags, exptime, length, data_block, command_name)
                    when "prepend", "append"
                        message = pre_append(key, length, data_block, command_name)
                    when "cas"
                        message = cas(key, flags, exptime, length, command_split[4], data_block)
                    when "get", "gets"
                        message = retrieve_items(command_split, command_name)
                    when "quit" # Terminate session
                        break
                    else # The command name received is not supported
                        message = INVALID_COMMAND_NAME_MSG
                    end

                    if !no_reply
                        connection.puts message
                    end
                end
                connection.close # Disconnect from the client
            rescue ArgumentClientError, TypeClientError => e # the input doesn't conform to the protocol
                # Clear buffer if there are remaining written bytes
                if connection.ready?
                    connection.read_nonblock(MAX_DATA_BLOCK_LENGTH)
                end
                connection.puts "CLIENT_ERROR #{e.message}\r\n" # Send error response
                request_handler(connection)
            rescue EOFError # Client has disconnected
                connection.close 
            end
        end

        def request_data_block_handler(connection, length)
            data_block = ""
            while line = connection.gets
                data_block += line
                break if data_block.length() >= (length.to_i + 2)
            end
            @util.validate_termination(data_block) # Check data_block terminates in "\r\n"
        end

        # [Add / Replace]: store data only if the server [does not / does] already hold data for key
        def add_replace(key, flags, exptime, length, data_block, command_name)
            start_reading
                cache_has_key = @cache.has_key?(key)
            finish_reading

            if (!cache_has_key && command_name == "add") || (cache_has_key && command_name == "replace")
                store_new_item(key, flags, exptime, length, data_block)
                message = STORED_MSG
            else
                message = NOT_STORED_MSG
            end
        end

        # Cas: set the data if it is not updated since last fetch
        def cas(key, flags, exptime, length, unique_cas_key, data_block)
            @util.validate_parameters([["cas", unique_cas_key]])

            start_reading
                cache_has_key = @cache.has_key?(key)
                equal_unique_cas_key = (cache_has_key ? @cache[key][4] == unique_cas_key.to_i : false)
            finish_reading

            if !cache_has_key # The key does not exist in the cache
                message = NOT_FOUND_MSG
            elsif !equal_unique_cas_key # The item has been modified since last fetch
                message = EXISTS_MSG
            else
                store_new_item(key, flags, exptime, length, data_block)
                message = STORED_MSG
            end
            message
        end
        
        # [Prepend / Append]: adds 'data_block' to an existing key [before / after] existing data_block
        def pre_append(key, length, data_block, command_name)
            @util.validate_parameters([ ["length", length, data_block.length()] ])

            start_reading
                cache_has_key = @cache.has_key?(key)
                previous_length = (cache_has_key ? @cache[key][2] : false)
            finish_reading
            
            if cache_has_key # the key exists in the Memcached server
                @util.validate_parameters([ ["data_block", data_block.length() + previous_length.to_i] ])  

                @mutex_writers.synchronize{ # Write shared cache
                    # If maximum capacity is reached, remove LRU item
                    if @total_length_stored + previous_length.to_i + length.to_i > MAX_CACHE_CAPACITY
                        remove_least_recently_used
                    end
                
                    # Append/prepend new item
                    @cache[key][2] = @cache[key][2].to_i + length.to_i # Add 'length' to the length of the existing item
                    @cache[key][3] = ( command_name == "prepend" ? data_block.concat(@cache[key][3]) : @cache[key][3].concat(data_block))
                    @cache[key][4] = @unique_cas_key # Update cas key of the stored item
                    update_global_variables(length.to_i)
                }
                message = STORED_MSG
            else
                message = NOT_STORED_MSG
            end
            message
        end
        
        # Retrieves the value stored at 'keys'.
        def retrieve_items(keys, command_name)
            raise ArgumentClientError, '<key>* must be provided' unless keys != []

            reply = ""
            keys.each do |key|
                @util.validate_parameters([["key", key]])

                start_reading
                    cache_has_key = @cache.has_key?(key)
                    if cache_has_key
                        flags, expdate, length, data_block, unique_cas_key = @cache[key]
                    end
                finish_reading
                
                # Keys that do not exists, do not appear on the response
                if cache_has_key
                    # LRU: delete item and re-add to keep the most recently used at the end
                    @mutex_writers.synchronize { # Write shared cache
                        @cache.delete(key)
                        @cache[key] = flags, expdate, length, data_block, unique_cas_key
                    }

                    reply += "VALUE #{key} #{flags} #{length}" + (command_name == "gets" ? " #{unique_cas_key}" : "") + "\r\n"
                    reply += "#{data_block}\r\n"
                end
            end
            reply += END_MSG
            reply 
        end

        def store_new_item(key, flags, exptime, length, data_block)
            @util.validate_parameters([["key", key], ["flags", flags], ["exptime", exptime], ["length", length, data_block.length()], ["data_block", data_block.length()] ])
            expdate = @util.expiration_date(exptime.to_i)
            
            # Determine the length added by the new insertion to the total length stored
            start_reading
                # If the key is already stored, the added length the length of the new item minus the previously stored length
                added_length = length.to_i - (@cache.has_key?(key) ?  @cache[key][2].to_i : 0)
            finish_reading

            @mutex_writers.synchronize { # Write shared cache
                # If maximum capacity is reached, remove LRU item
                if @total_length_stored + added_length > MAX_CACHE_CAPACITY
                    remove_least_recently_used
                end

                # Store new item
                @cache[key] = flags, expdate, length, data_block, @unique_cas_key
                update_global_variables(added_length)
            }
        end

        def start_reading
            @mutex_readers.synchronize{
                @readers_counter += 1
                if(@readers_counter == 1)
                    @mutex_writers.lock()
                end
            }
        end

        def finish_reading
            @mutex_readers.synchronize{
                @readers_counter -= 1
                if(@readers_counter == 0)
                    @mutex_writers.unlock()
                end
            }
        end
        
        # Update global cas key and total length stored after a new insertion
        def update_global_variables(added_length)
            @total_length_stored += added_length
            @unique_cas_key += 1
            @unique_cas_key = (@unique_cas_key).modulo(MAX_CAS_KEY)
        end

        def remove_least_recently_used
            deleted_item = @cache.shift # removes the first item of cache (LRU)
            @total_length_stored -= deleted_item[1][2].to_i
        end
    end
end