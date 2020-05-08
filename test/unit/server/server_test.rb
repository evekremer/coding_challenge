require_relative "../../test_helper"

# Unit test for Memcached::Server class
class ServerTest < BaseTest

  include Memcached::Mixin

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

  def test_invalid_termination_request_line
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_invalid_termination_datablock
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    invalid_termination = '$$'
    socket.puts "#{value}#{invalid_termination}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_key_starts_with_newline
    key = "\nkey"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> \n" as the command request line
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    #=> takes "<Memcached::GET_CMD_NAME> \n" as the command request line
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply
  end

  def test_key_control_chars_newline
    key = "memcached\nkey\n"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> memcached\n" as the command request line
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    #=> takes "<Memcached::GET_CMD_NAME> memcached\n" as the command request line
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply
  end

  def test_smaller_length_datablock
    incorrect_length = value.length - 4
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, incorrect_length, false, value, false
    
    excepted_reply = data_block_length_error_msg incorrect_length, value
    assert_equal excepted_reply, read_reply
  
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