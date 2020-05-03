require 'io/wait'

module Memcached
  class Server
    include Util
    
    def initialize(socket_address, socket_port)
      @server_socket = TCPServer.open(socket_address, socket_port)
      puts 'The server has been started'

      
      @cache_handler = CacheHandler.new

      @request_object = establish_connections
      @purge_expired_object = purge_expired_keys
      @request_object.join
      @purge_expired_object.join
    end

    private

    def establish_connections
      Thread.new{
        loop{
          client_connection = @server_socket.accept
          Thread.start(client_connection) do |conn|
            puts "Connection established => #{conn}"
            request_handler(conn)
            puts "Connection closed => #{conn}"
          end
        }
        @server_socket.close
      }
    end

    def request_handler(connection)
      while request_line = connection.gets
        begin
          command = validate_and_remove_ending!(request_line)
          command_split = command.split(/ /)
          command_name = command_split.shift
      
          no_reply = false

          if [SET_CMD_NAME, ADD_CMD_NAME, REPLACE_CMD_NAME, CAS_CMD_NAME, PREPEND_CMD_NAME, APPEND_CMD_NAME].include? command_name
            data_block = read_data_block_request(command_split[3], connection)
            
            if command_name == CAS_CMD_NAME
              storage_obj = CasCommand.new(command_split, data_block)
            else
              storage_obj = StorageCommand.new(command_name, command_split, data_block)
            end

            no_reply = storage_obj.no_reply
            message = @cache_handler.storage_handler(storage_obj)
    
          elsif [GET_CMD_NAME, GETS_CMD_NAME].include? command_name

            retrieval_obj = RetrievalCommand.new(command_name, command_split)
            message = @cache_handler.retrieval_handler(retrieval_obj)
            
          else # The command name received is not supported
            message = INVALID_COMMAND_NAME_MSG
          end

        rescue ArgumentClientError, TypeClientError => e # the input doesn't conform to the protocol
          # Clear buffer if there are remaining written bytes
          if connection.ready?
            connection.read_nonblock(MAX_DATA_BLOCK_LENGTH)
          end
          message = e.message
        end

        unless no_reply
          connection.puts message
        end
      end
      connection.close # Disconnect from the client
    end

    def read_data_block_request(length, connection)
      data_block = ""
      while line = connection.gets
        data_block += line
        break if data_block.length >= (length.to_i + 2)
      end

      validate_and_remove_ending!(data_block)
    end

    def purge_expired_keys
      Thread.new{
        loop{
          sleep(PURGE_EXPIRED_KEYS_FREQUENCY_SECS)
          @cache_handler.purge_expired_keys
        }
      }
    end
  end
end