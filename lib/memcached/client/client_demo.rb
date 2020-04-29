require_relative './util'
require 'socket'

module Memcached
  class ClientDemo
    def initialize(socket)
      @socket = socket
      establish_connection
    end

    def establish_connection
      begin
        puts "-" * 60
        puts "\n     Simple set and get commands\n\n"
        puts "-" * 60

        puts ">> set key1 1 1000000 9\r\n"
        puts ">> memcached\r\n"
        @socket.puts "set key1 1 1000000 9\r\n"
        @socket.puts "memcached\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> get key1\r\n"
        @socket.puts "get key1\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> {"key1" => "memcached"}
        puts "\n"

        puts ">> set key2 3 3000 4\r\n"
        puts ">> demo\r\n"
        @socket.puts "set key2 3 3000 4\r\n"
        @socket.puts "demo\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> get key2\r\n"
        @socket.puts "get key2\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> {"key2" => "demo"}
        puts "\n"

        puts "-" * 60
        puts "\n     Set with empty data_block\n\n"
        puts "-" * 60
        
        puts ">> set key5 3 1000 0\r\n"
        puts ">> \r\n"
        @socket.puts "set key5 3 1000 0\r\n"
        @socket.puts "\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED
        
        puts ">> get key5\r\n"
        @socket.puts "get key5\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> { "key5" => ""}
        puts "\n"
        
        puts "-" * 60
        puts "\n     Set and get expired item\n\n"
        puts "-" * 60

        puts ">> set key_exptime 0 2 5\r\n"
        puts ">> value\r\n"
        @socket.puts "set key_exptime 0 2 5\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED
        
        puts ">> Sleeps for #{PURGE_EXPIRED_KEYS_FREQUENCY_SECS+5} seconds...\n"
        sleep(PURGE_EXPIRED_KEYS_FREQUENCY_SECS+5)

        puts ">> get key_exptime\r\n"
        @socket.puts "get key_exptime\r\n"
        puts "#{@socket.gets}\n"
          #=> END (key_exptime item was deleted from the cache)

        puts "-" * 60
        puts "\n     Simple add and replace, then get multiple keys\n\n"
        puts "-" * 60

        puts ">> replace key1 4 75000 30\r\n"
        puts ">> this is the new value for key1\r\n"
        @socket.puts "replace key1 4 75000 30\r\n"
        @socket.puts "this is the new value for key1\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> add key3 0 8020 4\r\n"
        puts ">> ruby\r\n"
        @socket.puts "add key3 0 8020 4\r\n"
        @socket.puts "ruby\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> get key1 key3\r\n"
        @socket.puts "get key1 key3\r\n"
        5.times {puts "#{@socket.gets}"}
          #=> {"key1" => "this is the new value for key1", 
          #    "key3" => "ruby"}
        puts "\n"

        puts ">> replace key4 0 2 55\r\n"
        puts ">> Lorem ipsum dolor sit amet, consectetur adipiscing elit\r\n"
        @socket.puts "replace key4 0 2 55\r\n"
        @socket.puts "Lorem ipsum dolor sit amet, consectetur adipiscing elit\r\n"
        puts "#{@socket.gets}\n"
          #=> NOT_STORED

        puts ">> add key3 8 12 5\r\n"
        puts ">> value\r\n"
        @socket.puts "add key3 8 12 5\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> NOT_STORED

        puts ">> get key3 key4\r\n"
        @socket.puts "get key3 key4\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> {"key3" => "ruby"}
        
        puts "-" * 60
        puts "\n     Append and prepend to missing and existing keys\n\n"
        puts "-" * 60

        puts ">> append missing_key 0 222000 8\r\n"
        puts ">> abcd1234\r\n"
        @socket.puts "append missing_key 0 222000 8\r\n"
        @socket.puts "abcd1234\r\n"
        puts "#{@socket.gets}\n"
          #=> NOT_STORED

        puts ">> append key3 0 222000 9\r\n"
        puts ">>  on rails\r\n"
        @socket.puts "append key3 0 222000 9\r\n"
        @socket.puts " on rails\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> prepend key5 330 222000 #{"data_block_key5".length()}\r\n"
        puts ">> data_block_key5\r\n"
        @socket.puts "prepend key5 330 222000 #{"data_block_key5".length()}\r\n"
        @socket.puts "data_block_key5\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> get missing_key key3 key5\r\n"
        @socket.puts "get missing_key key3 key5\r\n"
        5.times {puts "#{@socket.gets}"}
          #=> { "key3" => "ruby on rails", 
          #       key5" => "data_block_key5"}
        puts "\n"
        
        puts "-" * 60
        puts "\n     CAS command\n\n"
        puts "-" * 60
        
        puts ">> cas key6 0 199000 9 1\r\n"
        puts ">> memcached\r\n"
        @socket.puts "cas key6 0 199000 9 1\r\n"
        @socket.puts "memcached\r\n"
        puts "#{@socket.gets}\n"
          #=> NOT_FOUND

        puts ">> set key6 0 199000 9\r\n"
        puts ">> memcached\r\n"
        @socket.puts "set key6 0 199000 9\r\n"
        @socket.puts "memcached\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> gets key6\r\n"
        @socket.puts "gets key6\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> { "key6" => "memcached", caskey: 8}
        puts "\n"
        cas_key_ini = 8
        

        puts ">> set key6 6 80000 13\r\n"
        puts ">> memcached_2.0\r\n"
        @socket.puts "set key6 6 80000 13\r\n"
        @socket.puts "memcached_2.0\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED and unique_cas_key is updated (with value 9)

        puts ">> cas key6 0 199000 13 #{cas_key_ini}\r\n"
        puts ">> memcached_2.1\r\n"
        @socket.puts "cas key6 0 199000 13 #{cas_key_ini}\r\n"
        @socket.puts "memcached_2.1\r\n"
        puts "#{@socket.gets}\n"
          #=> EXISTS - the item has been modified since last fetch

        puts ">> gets key6\r\n"
        @socket.puts "gets key6\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> { "key6" => "memcached_2.0", caskey: 9}
        puts "\n"
        cas_key_new = cas_key_ini + 1

        puts ">> cas key6 0 199000 13 #{cas_key_new}\r\n"
        puts ">> memcached_2.1\r\n"
        @socket.puts "cas key6 0 199000 13 #{cas_key_new}\r\n"
        @socket.puts "memcached_2.1\r\n"
        puts "#{@socket.gets}\n"
          #=> STORED

        puts ">> gets key6\r\n"
        @socket.puts "gets key6\r\n"
        3.times {puts "#{@socket.gets}"}
          #=> {"key6" => "memcached_2.1", caskey: 10}
        puts "\n"

        puts "-" * 60
        puts "\n     Invalid commands - error responses\n\n"
        puts "-" * 60

        puts "####     length = -1\n\n"
        puts ">> set key7 0 -1 -2\r\n"
        puts ">> value\r\n"
        @socket.puts "set key7 0 -1 -2\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <length> is not an unsigned integer

        puts "####     flags = -1\n\n"
        puts ">> set key8 -1 9000 5\r\n"
        puts ">> value\r\n"
        @socket.puts "set key8 -1 9000 5\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <flags> is not a 16-bit unsigned integer

        puts "####     exptime = b\n\n"
        puts ">> add key9 3 b c\r\n"
        puts ">> value\r\n"
        @socket.puts "add key9 3 b c\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <exptime> is not a 16-bit unsigned integer

        puts "####     cas_unique = q\n\n"
        puts ">> cas key10 3 9000 5 q noreply\r\n"
        puts ">> value\r\n"
        @socket.puts "cas key10 3 9000 5 q noreply\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <cas_unique> is not a 64-bit unsigned integer

        puts ">> set key11 3 9000 5 norep\r\n"
        puts ">> value\r\n"
        @socket.puts "set key11 3 9000 5 norep\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR "noreply" was expected as the 6th argument, but "norep" was received
        
        puts ">> set key12\r\n"
        puts ">> value\r\n"
        @socket.puts "set key12\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR The command has too few arguments

        puts ">> set key13 78 67 5 435 tf\r\n"
        puts ">> value\r\n"
        @socket.puts "set key13 78 67 5 435 tf\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR The command has too many arguments

        puts ">> invalid_cmd_name key14 3 9000 5\r\n"
        @socket.puts "invalid_cmd_name key14 3 9000 5\r\n"
        puts "#{@socket.gets}\n"
          #=> ERROR

        puts ">> get key"
        @socket.puts "get key"
        puts "#{@socket.gets + @socket.gets}\n"
          #=> CLIENT_ERROR Commands must be terminated by '\\r\n'
        
        key15 = "k" * (251)
        puts ">> add key that exceeds maximum length (250 characters)\n"
        @socket.puts "add #{key15} 8 1000 5\r\n"
        @socket.puts "value\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <key> has more than 250 characters

        data_block = "d" * (2**20 + 1)
        puts ">> set data_block that exceeds maximum length (1MB)\n"
        @socket.puts "set key16 3 300 #{data_block.length()}\r\n"
        @socket.puts "#{data_block}\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR

        key17 = "key\0withnull"
        puts ">> add key\\0withnull 4 24 14\r\n"
        puts ">> value_null_key\r\n"
        @socket.puts "add #{key17} 4 24 14\r\n"
        @socket.puts "value_null_key\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <key> must not include control characters

        puts ">> set key18 42 240 10\r\n"
        puts ">> value with smaller length\r\n"
        @socket.puts "set key18 42 240 10\r\n"
        @socket.puts "value with smaller length\r\n"
        puts "#{@socket.gets}\n"
          #=> CLIENT_ERROR <length> (10) is not equal to the length of the item's data_block (24)

        puts "-" * 60
        puts "\n\n>> Close connection"
        @socket.close
      rescue IOError => e
        puts e.message
        @socket.close
      end
    end
  end

  # Socket address and port set from command line arguments
  socket_address = ARGV[0] || "localhost"
  socket_port = ARGV[1] || 9999
  
  socket = TCPSocket.open( socket_address, socket_port )
  ClientDemo.new( socket )
end