require_relative "../lib/memcached/mixin"
require_relative "../lib/memcached/commands/retrieval"
require_relative "../lib/memcached/commands/storage"
require_relative "../lib/memcached/commands/cas"
require_relative "../lib/memcached/cache_handler"
require_relative '../lib/memcached/doubly_linked_list'
require_relative "../lib/memcached/lru_cache"

require "test/unit"
require 'socket'

class BaseTest < Test::Unit::TestCase
  def setup
    @socket = nil
  end

  def teardown
    @socket.close if @socket
  end

  def socket
    return @socket if @socket
    @socket = TCPSocket.open( "localhost", 9999 )
  end

  def send_storage_cmd(cmd_name, key, flags, exptime, length, unique_cas_key, value, noreply = false)
    request = "#{cmd_name} #{key} #{flags} #{exptime} #{length}"
    
    if unique_cas_key
      request += " #{unique_cas_key}"
    end

    if noreply
      request += " #{Memcached::NO_REPLY}"
    end

    request += Memcached::CMD_ENDING

    socket.puts request
    socket.puts "#{value}#{Memcached::CMD_ENDING}"
  end

  def send_get_cmd(key, gets = false)
    if gets
      cmd_name = Memcached::GETS_CMD_NAME
    else
      cmd_name = Memcached::GET_CMD_NAME
    end
    socket.puts "#{cmd_name} #{key}#{Memcached::CMD_ENDING}"
  end

  def expected_get_response(key, flags, length, value, unique_cas_key = false, multi = false)
    reply = "#{Memcached::VALUE_LABEL}#{key} #{flags} #{length}"
    if unique_cas_key
      reply += " #{unique_cas_key}"
    end
    reply += Memcached::CMD_ENDING
    reply += "#{value}#{Memcached::CMD_ENDING}"
    
    unless multi
      reply += Memcached::END_MSG
    end
    
    reply
  end

  # Returns cas key returned from the "gets" command of an existing key
  def get_cas_key(key)
    socket.puts "#{Memcached::GETS_CMD_NAME} #{key}\r\n"

    reply = @socket.gets
    cas_key = reply.split[4]
    cas_key = cas_key.delete Memcached::CMD_ENDING
    2.times {@socket.gets}
    cas_key.to_i
  end

  def send_get_multi_keys(keys, gets = false)
    if gets
      cmd = Memcached::GETS_CMD_NAME
    else
      cmd = Memcached::GET_CMD_NAME
    end
    keys.each do |key|
      cmd += " #{key}"
    end
    cmd += Memcached::CMD_ENDING
    socket.puts cmd
  end
  
  def read_reply num_lines = 1
    reply = ""
    num_lines.times { reply += @socket.gets }
    reply
  end

  def key
    "key_" + caller.first[/.*[` ](.*)'/, 1]
  end

  def value
    "value_" + caller.first[/.*[` ](.*)'/, 1]
  end
  alias :data_block :value

  def new_value
    'new_value'
  end

  def flags
    5
  end

  def exptime
    rand(200..500)
  end

  def expdate
    Time.now + rand(200..500)
  end

  def cas_key
    rand(500)
  end

  def wait_for_purge_exec
    sleep(Memcached::PURGE_EXPIRED_KEYS_FREQUENCY_SECS+2)
  end

  def data_to_hash key, flags, expdate, length, cas_key, data_block
    {:key=>key, :flags=>flags, :expdate=>expdate, :length=>length, :cas_key=>cas_key, :data_block=> data_block}
  end
end

class String
  def titlecase
    gsub(/\w+/, &:capitalize)
  end
end
