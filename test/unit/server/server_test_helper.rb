# frozen_string_literal: true

require_relative '../../test_helper'

class ServerTestHelper < BaseTest
  def setup
    @socket = nil
  end

  def teardown
    @socket&.close
  end

  def socket
    return @socket if @socket

    @socket = TCPSocket.open('localhost', 9999)
  end

  def assert_send_set(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end

  def send_storage_cmd(cmd_name, key, flags, exptime, length, value, noreply = false)
    request = "#{cmd_name} #{key} #{flags} #{exptime} #{length}"
    request += " #{Memcached::NO_REPLY}" if noreply
    request += Memcached::CMD_ENDING

    socket_puts request, value
  end

  def socket_puts(request, value)
    socket.puts request
    socket.puts "#{value}#{Memcached::CMD_ENDING}"
  end

  def send_get_cmd(key, gets = false)
    cmd_name = if gets
                 Memcached::GETS_CMD_NAME
               else
                 Memcached::GET_CMD_NAME
               end
    socket.puts "#{cmd_name} #{key}#{Memcached::CMD_ENDING}"
  end

  def assert_get(key, msg, gets = false)
    send_get_cmd key, gets
    assert_equal msg, read_reply
  end

  def assert_multine_get(key, flags, value, times = 3)
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(times)
  end

  # Returns cas key returned from the "gets" command of an existing key
  def get_cas_key(key)
    socket.puts "#{Memcached::GETS_CMD_NAME} #{key}#{Memcached::CMD_ENDING}"

    reply = socket.gets
    cas_key = reply.split[4]
    cas_key = cas_key.delete Memcached::CMD_ENDING
    2.times { socket.gets }
    cas_key.to_i
  end

  def send_get_multi_keys(keys, gets = false)
    cmd = if gets
            Memcached::GETS_CMD_NAME
          else
            Memcached::GET_CMD_NAME
          end
    keys.each do |key|
      cmd += " #{key}"
    end
    cmd += Memcached::CMD_ENDING
    socket.puts cmd
  end

  def read_reply(num_lines = 1)
    reply = ''
    num_lines.times { reply += socket.gets }
    reply
  end

  def wait_for_purge_exec
    sleep(Memcached::PURGE_EXPIRED_KEYS_FREQUENCY_SECS + 2)
  end

  def send_cas_cmd(key, flags, exptime, length, value, unique_cas_key, noreply = false)
    request = "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{length} #{unique_cas_key}"
    request += " #{Memcached::NO_REPLY}" if noreply
    request += Memcached::CMD_ENDING

    socket_puts request, value
  end

  def assert_send_cas(key, flags, exptime, value, unique_cas_key, msg = Memcached::STORED_MSG, length = value.length, noreply = false)
    send_cas_cmd key, flags, exptime, length, value, unique_cas_key, noreply
    assert_equal msg, read_reply
  end

  def assert_multine_gets(key, flags, value, cas_key, times = 3)
    send_get_cmd key, true
    expected_msg = expected_get_response key, flags, value.length, value, cas_key
    assert_equal expected_msg, read_reply(times)
  end

  def assert_send_replace(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end

  def assert_send_append(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end
end
