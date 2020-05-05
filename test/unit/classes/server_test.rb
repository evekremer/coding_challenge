require_relative "../../test_helper"

# Unit test for Memcached::Server class
class ServerTest < BaseTest

  ######## Incorrect command termination
  def test_numeric_request_line
    socket.puts 111111
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_string_request_line
    socket.puts ''
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  ######## Invalid command name error
  def test_invalid_command_name
    command_name = 'invalid_command_name'
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_request_line
    socket.puts "#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_command_name
    command_name = ''
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_case_sensitive_command_name_upcase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.upcase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_case_sensitive_command_name_titlecase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.titlecase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end
end