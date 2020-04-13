require 'socket'

module Memcached
    class Client
        def initialize(socket)
            @socket = socket
            @request_object = send_request
            @response_object = listen_response

            @request_object.join # send the request to server
            @response_object.join # receive response from server
        end

        def send_request
            begin
                puts "\n\n"
                puts "-" * 60
                puts "STORAGE COMMANDS\n"
                puts "-" * 60
                puts "First, enter the command line which looks like this:\n\n"
                puts ">>  <command name> <key> <flags> <exptime> <bytes> [noreply]\n"
                puts ">>  cas <key> <flags> <exptime> <bytes> <cas unique> [noreply]\n"
                puts "\nAfter this line, enter the data block of the item\n\n"
                puts "-" * 60
                puts "RETRIEVAL COMMANDS\n"
                puts "-" * 60
                puts "Enter one of the following command lines:\n\n"
                puts ">>  get <key>*\n"
                puts ">>  gets <key>*\n"
                puts "\nwhere <key>* means one or more key strings separated by whitespace\n"
                puts "-" * 60
                puts "\n\n\n"

                Thread.new do
                    loop do
                        message = $stdin.gets.chomp
                        @socket.puts message + "\r\n"
                    end
                end
            rescue IOError => e
                puts e.message
                @socket.close
            end
        end

        def listen_response
            begin
                Thread.new do
                    loop do
                        response = @socket.gets.chomp
                        puts "#{response}"
                    end
                end
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
    Client.new( socket )
end