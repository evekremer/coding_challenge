require_relative "./setup"

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

  def send_storage_cmd(cmd_name, key, flags, exptime, length, unique_cas_key, value, noreply)
    request = "#{cmd_name} #{key} #{flags} #{exptime} #{length}"
    request += (unique_cas_key ? " #{unique_cas_key}" : "") + (noreply ? " noreply\r\n" : "\r\n")

    socket.puts request
    socket.puts "#{value}\r\n"
  end

  def send_multi_get_cmd(keys, gets = false)
    cmd = gets ? "gets" : "get"
    keys.each do |key|
      cmd += " #{key}"
    end
    cmd += "\r\n"
    @socket.puts cmd

    #Get reply
    reply = ""
    (keys.length() * 2).times { reply += @socket.gets }
    reply += @socket.gets.chomp
    reply
  end

  def send_get_cmd(key, gets = false, length = false)
    cmd = gets ? "gets" : "get" + " #{key}\r\n"
    @socket.puts cmd

    #Get reply
    reply = ""
    reply += @socket.gets
    if reply != END_MSG
      if length
        reply += @socket.read(length+2)
      else
        reply += @socket.gets
      end
      reply += @socket.gets
    end
    reply
  end

  def expected_get_response(key, flags, length, value, gets = false, unique_cas_key = false)
    reply = "VALUE #{key} #{flags} #{length}"
    reply += gets ? " #{unique_cas_key}" : ""
    reply += "\r\n#{value}\r\n"
    reply += END_MSG
    reply
  end

  # def expected_multi_get_response(key, flags, length, value, gets = false, unique_cas_key = false)
  #   reply = "VALUE #{key} #{flags} #{length}"
  #   reply += gets ? " #{unique_cas_key}" : ""
  #   reply += "\r\n#{value}\r\n"
  #   reply += END_MSG
  #   reply
  # end

  def get_cas_key(key)
    send_get_cmd([key], true)
    
  end

  def key
    "key_" + caller.first[/.*[` ](.*)'/, 1]
  end

  def value
    "value_" + caller.first[/.*[` ](.*)'/, 1]
  end
end
