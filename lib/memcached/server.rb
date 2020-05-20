# frozen_string_literal: true

require 'io/wait'

module Memcached
  # Server class
  class Server
    include Mixin

    def initialize(socket_address, socket_port)
      @server_socket = TCPServer.open socket_address, socket_port
      @cache_handler = CacheHandler.new

      puts 'The server has been started'

      @request_object = establish_connections
      @purge_expired_object = purge_expired_keys
      @request_object.join
      @purge_expired_object.join
    end

    private

    def establish_connections
      Thread.new do
        loop do
          client_connection = @server_socket.accept
          Thread.start(client_connection) do |conn|
            puts "Connection established => #{conn}"
            request_handler conn
            puts "Connection closed => #{conn}"
          end
        end
        @server_socket.close
      end
    end

    def request_handler(connection)
      while (request_line = connection.gets)
        begin
          message = invoke_cache_handler (parse_request_line request_line), connection
        rescue ArgumentClientError, TypeClientError => e
          # Clear buffer if there are remaining written bytes
          connection.read_nonblock MAX_DATA_BLOCK_LENGTH if connection.ready?
          message = e.message
        end

        # Send server response via connection buffer
        connection.puts message unless message == NO_REPLY
      end

      # Disconnect from the client
      connection.close
    end

    def invoke_cache_handler(parameters, connection)
      cmd_name = parameters.shift
      if STORAGE_CMDS.include? cmd_name
        data_block = read_data_block_request parameters[3], connection
        @cache_handler.new_storage cmd_name, parameters, data_block
      elsif RETRIEVAL_CMDS.include? cmd_name
        @cache_handler.new_retrieval cmd_name, parameters
      else # Command name is not supported
        INVALID_COMMAND_NAME_MSG
      end
    end

    def parse_request_line(request_line)
      command = validate_and_remove_ending! request_line
      command.split(/ /)
    end

    # Read data block lines received from 'connection' buffer
    #   Until data block length is greater-than or equal-to the given 'length'
    #   (excluding command termination)
    def read_data_block_request(length, connection)
      data_block = ''
      while (line = connection.gets)
        data_block += line
        break if data_block.length >= (length.to_i + CMD_ENDING.length)
      end

      validate_and_remove_ending! data_block
    end

    # Purge expired keys stored into memcache
    # Within a frequency of <PURGE_EXPIRED_KEYS_FREQUENCY_SECS> seconds
    def purge_expired_keys
      Thread.new do
        loop  do
          sleep PURGE_EXPIRED_KEYS_FREQUENCY_SECS
          puts 'Purging expired keys...'
          @cache_handler.purge_expired_keys
        end
      end
    end
  end
end
