require_relative "../lib/memcached/util"

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
    request += (unique_cas_key ? " #{unique_cas_key}" : "") + (noreply ? " noreply\r\n" : "\r\n")

    socket.puts request
    socket.puts "#{value}\r\n"
  end

  def send_get_cmd(key, gets = false, length = false)
    cmd = (gets ? "gets" : "get") + " #{key}\r\n"
    @socket.puts cmd

    #Get reply
    reply = ""
    reply += @socket.gets
    if reply != Memcached::END_MSG
      reply += length ? @socket.read(length+2) : @socket.gets
      reply += @socket.gets
    end
    reply
  end

  def expected_get_response(key, flags, length, value, unique_cas_key = false, multi = false)
    reply = "VALUE #{key} #{flags} #{length}"
    reply += unique_cas_key ? " #{unique_cas_key}" : ""
    reply += "\r\n#{value}\r\n"
    if !multi
      reply += Memcached::END_MSG
    end
    reply
  end

  # Returns cas key returned from the "gets" command of an existing key
  def get_cas_key(key)
    @socket.puts "gets #{key}\r\n"

    reply = @socket.gets
    cas_key = reply.split[4]
    cas_key = cas_key.delete "\r\n"
    2.times {@socket.gets}
    cas_key.to_i
  end

  def send_get_multi_keys(keys, gets = false)
    cmd = gets ? "gets" : "get"
    keys.each do |key|
      cmd += " #{key}"
    end
    cmd += "\r\n"
    @socket.puts cmd
  end

  def send_multi_get_cmd(keys, gets = false)
    send_get_multi_keys(keys, gets)
    #Get reply
    # reply = ""
    # (keys.length() * 2).times { reply += @socket.gets }
    # reply += @socket.gets
    # reply
    read_reply((keys.length() * 2) + 1)
  end
  
  def read_reply(num_lines = 1)
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

  def wait_for_purge_exec
    sleep(Memcached::PURGE_EXPIRED_KEYS_FREQUENCY_SECS+2)
  end
end
