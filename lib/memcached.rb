require_relative './memcached/mixin'
require_relative './memcached/commands/storage'
require_relative './memcached/commands/cas'
require_relative './memcached/commands/retrieval'
require_relative './memcached/cache_handler'
require_relative './memcached/doubly_linked_list'
require_relative './memcached/lru_cache'
require 'socket'
require_relative './memcached/server'

socket_address = ARGV[0] || "0.0.0.0" # any client anywhere can connect
socket_port = ARGV[1] || 9999
Memcached::Server.new socket_address, socket_port