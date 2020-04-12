require 'socket'
require_relative './memcached/util'
require_relative './memcached/server'

socket_address = ARGV[0] || "localhost"
socket_port = ARGV[1] || 9999
Memcached::Server.new( socket_address, socket_port )