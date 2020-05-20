# frozen_string_literal: true

require_relative '../mixin'
require 'socket'

module Memcached
  class ClientDemo
    def initialize(socket)
      @socket = socket

      # Storage commands parameters
      @storage_cmd_name = Memcached::SET_CMD_NAME
      @key = 'key1'
      @flags = 1
      @exptime = 1_000_000
      @data_block = 'memcached'
      @cas_key = false
      @no_reply = false

      # Retrieval commands parameters
      @retrieval_cmd_name = Memcached::GET_CMD_NAME
      @keys = [@key]
      establish_connection
    end

    def print_title(title)
      puts '-' * 60
      puts "\n     #{title}\n\n"
      puts '-' * 60
      puts "\n"
    end

    def retrieval_request_handler(num_lines = 1)
      keys = ''
      @keys.each { |key| keys += " #{key}" }
      request_line = "#{@retrieval_cmd_name}#{keys}#{Memcached::CMD_ENDING}"

      puts ">> #{request_line}"
      @socket.puts request_line
      print_reply num_lines
    end

    def request_line(length = false)
      length ||= @data_block.length
      request = "#{@storage_cmd_name} #{@key} #{@flags} #{@exptime} #{length}"
      request += " #{@cas_key}" if @cas_key
      request += " #{@no_reply}" if @no_reply
      request += Memcached::CMD_ENDING.to_s
    end

    def storage_request_handler(length = false)
      command = request_line length
      print_command command
      send_command command
    end

    def print_command(command)
      puts ">> #{command}"
      puts ">> #{@data_block}#{Memcached::CMD_ENDING}"
    end

    def send_command(command)
      @socket.puts command
      @socket.puts "#{@data_block}#{Memcached::CMD_ENDING}"
      print_reply
    end

    def print_reply(num_lines = 1)
      num_lines.times { puts @socket.gets.to_s } # Print server response
      puts "\n"
    end

    def print_comment(comment)
      puts "####     #{comment}\n\n"
    end

    def establish_connection
      print_title 'Simple set and get commands'

      storage_request_handler #=> Memcached::STORED
      retrieval_request_handler 3 #=> {"key1" => "memcached"}

      @key = 'key2'
      @flags = 3
      @exptime = 3000
      @data_block = 'demo'
      storage_request_handler #=> Memcached::STORED

      @keys = [@key]
      retrieval_request_handler 3 #=> {"key2" => "demo"}

      print_title 'Set with empty data_block'

      @key = 'key5'
      @flags = 3
      @exptime = 1000
      @data_block = ''
      storage_request_handler #=> Memcached::STORED

      @keys = [@key]
      retrieval_request_handler 3 #=> { "key5" => ""}

      print_title 'Set and get expired item'

      @key = 'key_imm_expired'
      @keys = [@key]
      @flags = 4
      @exptime = -1
      @data_block = 'value immediatelly expired'
      storage_request_handler #=> Memcached::STORED

      retrieval_request_handler
      #=> Memcached::END (expired but not yet removed from cache)

      @key = 'key_exptime_demo'
      @keys = [@key]
      @flags = 8
      @exptime = 3
      @data_block = 'value exptime demo'
      storage_request_handler #=> Memcached::STORED

      puts ">> Sleeps #{PURGE_EXPIRED_KEYS_FREQUENCY_SECS + 5} seconds...\n\n"
      sleep PURGE_EXPIRED_KEYS_FREQUENCY_SECS + 5

      retrieval_request_handler #=> Memcached::END (purged from the cache)

      print_title 'Simple add and replace, then get multiple keys'

      @storage_cmd_name = Memcached::REPLACE_CMD_NAME
      @key = 'key1'
      @flags = 4
      @exptime = 75_000
      @data_block = 'this is the new value for key1'
      storage_request_handler #=> Memcached::STORED

      @storage_cmd_name = Memcached::ADD_CMD_NAME
      @key = 'key3'
      @flags = 0
      @exptime = 8020
      @data_block = 'ruby'
      storage_request_handler #=> Memcached::STORED

      @keys = %w[key1 key3]
      retrieval_request_handler 5
      #=> {"key1" => "this is the new value for key1",
      #    "key3" => "ruby"}

      @storage_cmd_name = Memcached::REPLACE_CMD_NAME
      @key = 'key4'
      @exptime = 2
      @data_block = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'
      storage_request_handler #=> Memcached::NOT_STORED

      @storage_cmd_name = Memcached::ADD_CMD_NAME
      @key = 'key3'
      @flags = 8
      @exptime = 12
      @data_block = 'value'
      storage_request_handler #=> Memcached::NOT_STORED

      @keys = %w[key3 key4]
      retrieval_request_handler 3 #=> {"key3" => "ruby"}

      print_title 'Append and prepend to missing and existing keys'

      @storage_cmd_name = Memcached::APPEND_CMD_NAME
      @key = 'missing_key'
      @flags = 3
      @exptime = 222_000
      @data_block = 'abcd1234'
      storage_request_handler #=> Memcached::NOT_STORED

      @key = 'key3'
      @data_block = ' on rails'
      storage_request_handler #=> Memcached::STORED

      @storage_cmd_name = Memcached::PREPEND_CMD_NAME
      @key = 'key5'
      @flags = 330
      @data_block = 'data_block_key5'
      storage_request_handler #=> Memcached::STORED

      @keys = %w[missing_key key3 key5]
      retrieval_request_handler 5
      #=> { "key3" => "ruby on rails",
      #       key5" => "data_block_key5"}

      print_title 'CAS command'

      @storage_cmd_name = Memcached::CAS_CMD_NAME
      @key = 'key6'
      @flags = 0
      @exptime = 199_000
      @data_block = 'memcached'
      @cas_key = 1
      storage_request_handler #=> Memcached::NOT_FOUND

      @storage_cmd_name = Memcached::SET_CMD_NAME
      @cas_key = false
      storage_request_handler #=> Memcached::STORED

      @retrieval_cmd_name = Memcached::GETS_CMD_NAME
      @keys = [@key]
      retrieval_request_handler 3
      #=> { "key6" => "memcached", caskey: 10}

      @storage_cmd_name = Memcached::SET_CMD_NAME
      @flags = 6
      @exptime = 80_000
      @data_block = 'memcached_2.0'
      @cas_key = false
      storage_request_handler
      #=> Memcached::STORED and unique_cas_key is updated (with value 11)

      @storage_cmd_name = Memcached::CAS_CMD_NAME
      @flags = 0
      @exptime = 199_000
      @data_block = 'memcached_2.1'
      @cas_key = 10
      storage_request_handler
      #=> Memcached::EXISTS - the item has been modified since last fetch

      retrieval_request_handler 3
      #=> { "key6" => "memcached_2.0", caskey: 11}

      @cas_key += 1
      storage_request_handler #=> STORED

      retrieval_request_handler 3
      #=> {"key6" => "memcached_2.1", caskey: 12}

      print_title 'Invalid commands - error responses'

      print_comment 'length = -1'

      @storage_cmd_name = Memcached::SET_CMD_NAME
      @key = 'key7'
      @flags = 0
      @exptime = -1
      length = -2
      @data_block = 'value'
      @cas_key = false
      storage_request_handler length #=> Memcached::LENGTH_TYPE_MSG

      print_comment 'flags = -1'

      @key = 'key8'
      @flags = -1
      @exptime = 9000
      storage_request_handler #=> Memcached::FLAGS_TYPE_MSG

      print_comment 'exptime = "b"'

      @storage_cmd_name = Memcached::ADD_CMD_NAME
      @key = 'key9'
      @flags = 3
      @exptime = 'b'
      storage_request_handler #=> Memcached::EXPTIME_TYPE_MSG

      print_comment 'cas_key = "q"'

      @storage_cmd_name = Memcached::CAS_CMD_NAME
      @key = 'key10'
      @flags = 3
      @exptime = 9000
      @cas_key = 'q'
      @no_reply = Memcached::NO_REPLY
      storage_request_handler #=> Memcached::CAS_KEY_TYPE_MSG

      @storage_cmd_name = Memcached::SET_CMD_NAME
      @key = 'key11'
      @cas_key = false
      @no_reply = 'norep'
      storage_request_handler
      #=> CLIENT_ERROR
      #   "noreply" was expected as the 6th argument, but "norep" was received

      @no_reply = false
      command = "#{Memcached::SET_CMD_NAME} key12#{Memcached::CMD_ENDING}"
      print_command command
      send_command command #=> Memcached::TOO_FEW_ARGUMENTS_MSG

      command = "#{Memcached::SET_CMD_NAME} key13 78 67 5 435 tf"
      command += Memcached::CMD_ENDING.to_s
      print_command command
      send_command command #=> Memcached::TOO_MANY_ARGUMENTS_MSG

      command_name = 'invalid_cmd_name'
      key = 'key14'
      cmd = "#{command_name} #{key} #{@flags} #{@exptime} #{@data_block.length}"
      cmd += Memcached::CMD_ENDING.to_s
      puts ">> #{cmd}"
      @socket.puts cmd
      print_reply #=> Memcached::ERROR

      command = "#{Memcached::SET_CMD_NAME} key15 78 67 5"
      print_command command
      send_command command #=> Memcached::CMD_TERMINATION_MSG

      print_comment "set key exceeds max length (#{MAX_KEY_LENGTH} characters)"

      @key = 'k' * (MAX_KEY_LENGTH + 1)
      send_command request_line #=> Memcached::KEY_TOO_LONG_MSG

      print_comment 'set data_block that exceeds maximum length (1MB)'

      @key = 'key16'
      @data_block = 'd' * (MAX_DATA_BLOCK_LENGTH + 1)
      send_command request_line #=> Memcached::DATA_BLOCK_TOO_LONG_MSG

      @key = "key\0withnull"
      @data_block = 'value_null_key'
      storage_request_handler #=> Memcached::KEY_WITH_CONTROL_CHARS_MSG

      @key = 'key18'
      @data_block = 'value with smaller length'
      length = @data_block.length - 8
      storage_request_handler length
      #=> CLIENT_ERROR
      #   <length> (17) is not equal to the length of the item's data_block (24)

      print_comment 'Close connection'
      @socket.close
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end

  # Socket address and port set from command line arguments
  socket_address = ARGV[0] || 'localhost'
  socket_port = ARGV[1] || 9999

  socket = TCPSocket.open socket_address, socket_port
  ClientDemo.new socket
end
