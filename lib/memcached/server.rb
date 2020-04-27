require 'io/wait'
module Memcached
    class Server
        include Util
        
        def initialize(socket_address, socket_port)
            @server_socket = TCPServer.open(socket_address, socket_port)
            @cache = LRUCache.new(MAX_CACHE_CAPACITY, MAX_CAS_KEY)
            @readers_counter = 0
            puts 'The server has been started'

            @request_object = establish_connections
            @purge_expired_object = purge_expired_keys

            @request_object.join
            @purge_expired_object.join

            @reply_message = ""
        end

        def cache_has_key(key)
            @cache.cache_has_key(key)
        end

        def cache
            @cache
        end

        def message=(msg)
            @reply_message = msg
        end
    
        def message
            @reply_message
        end

        private

        def establish_connections
            Thread.new do
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
        end

        def request_handler(connection)
            while request_line = connection.gets
                begin
                    command = validate_command_termination!(request_line)
                    command_split = command.split(/ /)
                    command_name = command_split.shift
                
                    case command_name
                    when SET_CMD_NAME
                        cmd = SetCommand.new(command_name, command_split, connection)
                    when ADD_CMD_NAME, REPLACE_CMD_NAME
                        cmd = AddReplaceCommand.new(command_name, command_split, connection)
                    when PREPEND_CMD_NAME, APPEND_CMD_NAME
                        cmd = PreAppendCommand.new(command_name, command_split, connection)
                    when CAS_CMD_NAME
                        cmd = CasCommand.new(command_name, command_split, connection, command_split[4])
                    when GET_CMD_NAME, GETS_CMD_NAME
                        cmd = RetrievalCommand.new(command_name, command_split)
                    else # The command name received is not supported
                        message = INVALID_COMMAND_NAME_MSG
                    end

                rescue ArgumentClientError, TypeClientError => e # the input doesn't conform to the protocol
                    # Clear buffer if there are remaining written bytes
                    if connection.ready?
                        connection.read_nonblock(MAX_DATA_BLOCK_LENGTH)
                    end
                    message = CLIENT_ERROR + e.message + CMD_ENDING
                    # request_handler(connection)
                end

                unless cmd && cmd.no_reply
                    connection.puts message
                end
            end
            connection.close # Disconnect from the client
        end

        def purge_expired_keys
            Thread.new do
                loop{
                    sleep(PURGE_EXPIRED_KEYS_FREQUENCY_SECS)
                    @cache.purge_expired_keys
                }
            end
        end
    end
end