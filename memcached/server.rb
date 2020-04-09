require 'socket'
require_relative "./util"

module Memcached
    
    class Server
        def initialize(socket_address, socket_port)
            @server_socket = TCPServer.open(socket_address, socket_port)
            @cache = Hash.new
            @mutex_readers = Mutex.new
            @mutex_writers = Mutex.new
            @readers_counter = 0
            @unique_cas_key = 0
            @stored_total_length = 0
            @aux = Memcached::Util.new
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
                    command = @aux.validate_termination(connection.gets)
                    command_split = command.split(/ /)
                    command_name = command_split.shift

                    if ["set", "add", "replace", "prepend", "append", "cas"].include? command_name
                        key, flags, exptime, length = command_split
                        data_block = connection.read_nonblock(Util::MAX_BUFFER_LENGTH)

                        new_data = data_block
                        while new_data.length() == Util::MAX_BUFFER_LENGTH && data_block.length() <= Util::MAX_VALUE_LENGTH+2
                            new_data = connection.read_nonblock(Util::MAX_BUFFER_LENGTH)
                            data_block += new_data
                        end
                        
                        raise TypeError, "<value> has more than #{Util::MAX_VALUE_LENGTH} characters" unless data_block.length() <= Util::MAX_VALUE_LENGTH+2
                        data_block = @aux.validate_termination(data_block) # Check data_block terminates by "\r\n"
                        
                        # Check if the optional 'noreply' parameter is included in 'command'
                        no_reply = @aux.has_no_reply(command_split, command_name == "cas" ? 6 : 5)
                    end
                    
                    case command_name
                    when "set"
                        store_new_item(key, flags, exptime, length, data_block)
                        message = Util::STORED_MSG
                    when "add", "replace"
                        start_reading
                            cache_has_key = @cache.has_key?(key)
                        finish_reading

                        if (!cache_has_key && command_name == "add") || (cache_has_key && command_name == "replace")
                            store_new_item(key, flags, exptime, length, data_block)
                            message = Util::STORED_MSG
                        else
                            message = Util::NOT_STORED_MSG
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
                        message = Util::INVALID_COMMAND_NAME_MSG
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
            raise TypeError, '<cas_unique> is not a 64-bit unsigned integer' unless @aux.is_unsigned_i(unique_cas_key, 64)
            start_reading
                cache_has_key = @cache.has_key?(key)
                equal_unique_cas_key = (cache_has_key ? @cache[key][4] == unique_cas_key.to_i : false)
            finish_reading

            if !cache_has_key # The key does not exist in the cache
                message = Util::NOT_FOUND_MSG
            elsif !equal_unique_cas_key # The item has been modified since last fetch
                message = Util::EXISTS_MSG
            else
                store_new_item(key, flags, exptime, length, value)
                message = Util::STORED_MSG
            end
            message
        end
        
        # [Prepend / Append]: adds 'value' to an existing key [before / after] existing value
        def pre_append(key, length, value, pre = false)
            @aux.validate_parameters([ ["length", length, value.length()] ])

            start_reading
                cache_has_key = @cache.has_key?(key)
                prev_length = (cache_has_key ? @cache[key][2] : false)
            finish_reading
            
            if cache_has_key # the key exists in the Memcached server       
                @aux.validate_parameters([ ["value", value.length() + prev_length.to_i] ])  

                @mutex_writers.synchronize{ # Write shared cache
                    if @stored_total_length + prev_length.to_i + length.to_i >= Util::MAX_CACHE_CAPACITY # maximum capicity is reached
                        remove_LRU_item
                    end
                
                    @cache[key][2] = @cache[key][2].to_i + length.to_i # Add 'length' to the previous length
                    @cache[key][3] = ( pre ? value.concat(@cache[key][3]) : @cache[key][3].concat(value))
                    @cache[key][4] = @unique_cas_key # Update cas key
                    @stored_total_length += length.to_i
                    update_cas_key
                }
                message = Util::STORED_MSG
            else
                message = Util::NOT_STORED_MSG
            end
            message
        end
        
        # Retrieves the value stored at 'keys'. Keys that do not exists do not appear on the response
        def retrieve_items(keys, gets = false)
            raise ArgumentError, '<key>* must be provided' unless keys != []

            reply = ""
            keys.each do |key|
                @aux.validate_parameters([["key", key]])

                start_reading
                    cache_has_key = @cache.has_key?(key)
                    if cache_has_key
                        flags, expdate, length, value, unique_cas_key = @cache[key]
                    end
                finish_reading
                
                if cache_has_key
                    # LRU: delete item and re-add to keep the most recently used at the end
                    @mutex_writers.synchronize { # Write shared cache
                        @cache.delete(key)
                        @cache[key] = flags, expdate, length, value, unique_cas_key
                    }
                    reply += "VALUE #{key} #{flags} #{length}" + (gets ? " #{unique_cas_key}" : "") + "\r\n"
                    reply += "#{value}\r\n"
                end
            end
            reply += Util::END_MSG
            reply 
        end

        def store_new_item(key, flags, exptime, length, value)
            @aux.validate_parameters([["key", key], ["flags", flags], ["exptime", exptime], ["length", length, value.length()], ["value", value.length()] ])
            expdate = @aux.expiration_date(exptime.to_i)
            
            added_length = length.to_i
            start_reading
                added_length -= (@cache.has_key?(key) ?  @cache[key][2].to_i : 0)
            finish_reading

            @mutex_writers.synchronize { # Write shared cache
                if @stored_total_length + added_length >= Util::MAX_CACHE_CAPACITY # maximum capicity is reached
                    remove_LRU_item
                end
                # Store new item
                @cache[key] = flags, expdate, length, value, @unique_cas_key
                @stored_total_length += added_length
                update_cas_key
            }
        end

        private

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
        
        def update_cas_key
            @unique_cas_key += 1
            @unique_cas_key = (@unique_cas_key).modulo(Util::MAX_CAS_KEY)
        end

        def remove_LRU_item
            deleted_item = @cache.shift # remove the least recently used item (LRU)
            @stored_total_length -= deleted_item[1][2].to_i
        end
    end

    socket_address = ARGV[0] || "localhost"
    socket_port = ARGV[1] || 9999
    Server.new( socket_address, socket_port )
end