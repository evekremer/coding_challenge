require 'socket'

module Memcached
    class ClientDemo
        def initialize(socket)
            @socket = socket
            establish_communication
        end

        def establish_communication
            begin
                #### Simple set
                puts "\n#######     Simple set\n\n"
                
                puts ">> set key1 0 1000000 9\r\n"
                puts ">> memcached\r\n"
                @socket.puts "set key1 0 1000000 9\r\n"
                @socket.puts "memcached\r\n"
                puts "#{@socket.gets}\n"
                # #=> STORED

                puts ">> get key1\r\n"
                @socket.puts "get key1\r\n"
                3.times {puts "#{@socket.gets}"}
                    #=> {"key1" => "memcached"}
                puts "\n"

                #### Set with an expiration timeout
                puts "\n#######     Set with an expiration timeout\n\n"

                puts ">> set key2 0 2 5\r\n"
                puts ">> hello\r\n"
                @socket.puts "set key2 0 2 5\r\n"
                @socket.puts "hello\r\n"
                puts "#{@socket.gets}\n"
                    #=> STORED
                
                puts ">> Sleeps for 3 seconds..."
                sleep(3)

                puts ">> get key2\r\n"
                @socket.puts "get key2\r\n"
                puts "#{@socket.gets}\n"
                    #=> END (key2 was deleted from the memcached server)

                #### Simple add and replace, then get multiple keys
                puts "\n#######     Simple add and replace, then get multiple keys\n\n"

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

                puts ">> set key4 0 2 55\r\n"
                puts ">> Lorem ipsum dolor sit amet, consectetur adipiscing elit\r\n"
                @socket.puts "set key4 0 2 55\r\n"
                @socket.puts "Lorem ipsum dolor sit amet, consectetur adipiscing elit\r\n"
                puts "#{@socket.gets}\n"
                    #=> STORED

                puts ">> get key1 key2 key3 key4\r\n"
                @socket.puts "get key1 key2 key3 key4\r\n"
                7.times {puts "#{@socket.gets}"}
                    #=> {"key1" => "new value for key1", 
                    #    "key3" => "ruby", 
                    #    key4" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit"}
                puts "\n"
                
                #### Set with empty data_block
                puts "\n#######     Set with empty data_block\n\n"
                
                puts ">> set key5 3 1000 0\r\n"
                puts ">> \r\n"
                @socket.puts "set key5 3 1000 0\r\n"
                @socket.puts "\r\n"
                puts "#{@socket.gets}\n"

                puts ">> get key5\r\n"
                @socket.puts "get key5\r\n"
                3.times {puts "#{@socket.gets}"}
                    #=> { "key5" => nil}
                puts "\n"

                #### Append and prepend to a missing and existing key
                puts "\n#######     Append and prepend to a missing and existing key\n\n"
                
                puts ">> get key3 key5\r\n"
                @socket.puts "get key3 key5\r\n"
                5.times {puts "#{@socket.gets}"}
                puts "\n"

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

                puts ">> prepend key5 330 222000 8\r\n"
                puts ">> abcd1234\r\n"
                @socket.puts "prepend key5 330 222000 8\r\n"
                @socket.puts "abcd1234\r\n"
                puts "#{@socket.gets}\n"
                    #=> STORED

                puts ">> get missing_key key3 key5\r\n"
                @socket.puts "get missing_key key3 key5\r\n"
                5.times {puts "#{@socket.gets}"}
                    #=> { "key3" => "ruby on rails", 
                    #       key5" => "abcd1234"}
                puts "\n"
                
                #### CAS command
                puts "\n#######     CAS command\n\n"
                
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
                reply = @socket.gets
                cas_key_ini = get_cas_key(reply)
                
                puts "#{reply}"
                2.times {puts "#{@socket.gets}"}
                puts "\n"

                puts ">> set key6 6 80000 13\r\n"
                puts ">> memcached_2.0\r\n"
                @socket.puts "set key6 6 80000 13\r\n"
                @socket.puts "memcached_2.0\r\n"
                puts "#{@socket.gets}\n"
                    #=> STORED and unique_cas_key is updated

                puts ">> cas key6 0 199000 13 #{cas_key_ini}\r\n"
                puts ">> memcached_2.1\r\n"
                @socket.puts "cas key6 0 199000 13 #{cas_key_ini}\r\n"
                @socket.puts "memcached_2.1\r\n"
                puts "#{@socket.gets}\n"
                    #=> EXISTS - the item has been modified since last fetch

                puts ">> gets key6\r\n"
                @socket.puts "gets key6\r\n"
                reply = @socket.gets
                cas_key_new = get_cas_key(reply)
                
                puts "#{reply}"
                2.times {puts "#{@socket.gets}"}
                puts "\n"

                puts ">> cas key6 0 199000 13 #{cas_key_new}\r\n"
                puts ">> memcached_2.1\r\n"
                @socket.puts "cas key6 0 199000 13 #{cas_key_new}\r\n"
                @socket.puts "memcached_2.1\r\n"
                puts "#{@socket.gets}\n"
                    #=> STORED

                puts ">> gets key6\r\n"
                @socket.puts "gets key6\r\n"
                3.times {puts "#{@socket.gets}"}
                    #=> {"key6" => "memcached_2.0"}
                puts "\n"

                #### Invalid commands - error strings
                puts "\n#### Invalid commands - error strings\n\n"

                puts ">> set key7 0 -1 -2\r\n"
                puts ">> value\r\n"
                @socket.puts "set key7 0 -1 -2\r\n"
                @socket.puts "value\r\n"
                puts "#{@socket.gets}\n"
                    #=> CLIENT_ERROR

                puts ">> set key7 -1 9000 5\r\n"
                puts ">> value\r\n"
                @socket.puts "set key7 -1 9000 5\r\n"
                @socket.puts "value\r\n"
                puts "#{@socket.gets}\n"
                    #=> CLIENT_ERROR

                puts ">> set key7\r\n"
                puts ">> value\r\n"
                @socket.puts "set key7\r\n"
                @socket.puts "value\r\n"
                puts "#{@socket.gets}\n"
                    #=> CLIENT_ERROR

                puts ">> add key8 a b c\r\n"
                puts ">> value\r\n"
                @socket.puts "add key8 a b c\r\n"
                @socket.puts "value\r\n"
                puts "#{@socket.gets}\n"
                    #=> CLIENT_ERROR

                puts ">> cas key10 3 9000 5\r\n"
                puts ">> value\r\n"
                @socket.puts "cas key10 3 9000 5\r\n"
                @socket.puts "value\r\n"
                puts "#{@socket.gets}\n"
                    #=> CLIENT_ERROR

                puts ">> invalid_cmd_name key9 3 9000 5\r\n"
                @socket.puts "invalid_cmd_name key9 3 9000 5\r\n"
                puts "#{@socket.gets}\n"
                    #=> ERROR

                puts "\n\n>> quit"
                @socket.puts "quit"
                @socket.close
            rescue IOError => e
                puts e.message
                # e.backtrace
                @socket.close
            end
        end

        def get_cas_key(reply)
            cas_key = reply.split[4]
            cas_key = cas_key.delete "\r\n"
            cas_key
        end
    end

    # Socket address and port set from command line arguments
    socket_address = ARGV[0] || "localhost"
    socket_port = ARGV[1] || 9999
    
    socket = TCPSocket.open( socket_address, socket_port )
    ClientDemo.new( socket )
end