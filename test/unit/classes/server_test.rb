require_relative "../test_helper"

# Unit test for Memcached::Server class
class ServerTest < BaseTest

  # Incorrect command termination

  def test_numeric_request_line
    socket.puts 111111
    reply = read_reply(2)
    assert_equal CMD_TERMINATION_MSG, reply
  end

  def test_nil_request_line
    socket.puts nil
    reply = read_reply(2)
    assert_equal CMD_TERMINATION_MSG, reply
  end

  def test_empty_string_request_line
    socket.puts ''
    reply = read_reply(2)
    assert_equal CMD_TERMINATION_MSG, reply
  end

  # Invalid command name error

  def test_invalid_command_name
    command_name = 'invalid_command_name'
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{CMD_ENDING}"
    assert_equal INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal END_MSG, reply
  end

  def test_empty_request_line
    socket.puts "#{CMD_ENDING}"
    assert_equal INVALID_COMMAND_NAME_MSG, read_reply
  end

  def test_empty_command_name
    command_name = ''
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{CMD_ENDING}"
    assert_equal INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal END_MSG, reply
  end

  def test_case_sensitive_replace_upcase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.upcase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_case_sensitive_replace_titlecase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.titlecase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end
end