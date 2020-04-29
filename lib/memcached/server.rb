require 'io/wait'
require 'socket'

module Memcached
  class Server
    include Util
    
    def initialize(socket_address, socket_port)
      @server_socket = TCPServer.open(socket_address, socket_port)
      puts 'The server has been started'

      @cache_handler = CacheHandler.new

      establish_connections
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
          command = validate_and_remove_ending!(request_line)
          command_split = command.split(/ /)
          command_name = command_split.shift
      
          no_reply = false

          if [SET_CMD_NAME, ADD_CMD_NAME, REPLACE_CMD_NAME, CAS_CMD_NAME, PREPEND_CMD_NAME, APPEND_CMD_NAME].include? command_name
            data_block = read_data_block_request(command_split[3], connection)
            
            if command_name == CAS_CMD_NAME
              storage_obj = CasCommand.new(parameters, data_block)
            else
              storage_obj = StorageCommand.new(parameters, data_block)
            end

            no_reply = storage_obj.no_reply
            message = @cache_handler.storage_handler(storage_obj)
    
          elsif [GET_CMD_NAME, GETS_CMD_NAME].include? command_name
            retrieval_obj = RetrievalCommand.new(command_name, parameters)
            message = @cache_handler.retrieval_handler(retrieval_obj) 
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

        unless no_reply
          connection.puts message
        end
      end
      connection.close # Disconnect from the client
    end

    private

    def validate_and_remove_ending!(command)
      command_ending = command[-2..-1] || command
      raise ArgumentClientError, CMD_TERMINATION_MSG unless command_ending == CMD_ENDING
  
      command[0..-3] || command
    end

    def read_data_block_request(length, connection)
      data_block = ""
      while line = connection.gets
        data_block += line
        break if data_block.length() >= (length.to_i + 2)
      end

      validate_and_remove_ending!(data_block)
    end
  end
end