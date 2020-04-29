require_relative './memcached/util'
require_relative './memcached/commands/*'
require_relative './memcached/cache_handler'
require_relative './memcached/item'
require_relative './memcached/lru_cache'
require_relative './memcached/server'

socket_address = ARGV[0] || "0.0.0.0" # any client anywhere can connect
socket_port = ARGV[1] || 9999
Memcached::Server.new(socket_address, socket_port)