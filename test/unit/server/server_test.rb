# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
class ServerTest < ServerTestHelper
  include Memcached::Mixin

  def test_numeric_request_line
    socket.puts 111_111
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_empty_string_request_line
    socket.puts ''
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_invalid_termination_request_line
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_invalid_termination_datablock
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    socket.puts "#{value}$$"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_key_starts_with_newline
    key = "\nkey"
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> \n" as the command request line
    assert_send_set key, flags, exptime, value, Memcached::CMD_TERMINATION_MSG

    #=> takes "<Memcached::GET_CMD_NAME> \n" as the command request line
    assert_get key, Memcached::CMD_TERMINATION_MSG
  end

  def test_key_control_chars_newline
    key = "memcached\nkey\n"
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> memcached\n" as the command request line
    assert_send_set key, flags, exptime, value, Memcached::CMD_TERMINATION_MSG

    #=> takes "<Memcached::GET_CMD_NAME> memcached\n" as the command request line
    assert_get key, Memcached::CMD_TERMINATION_MSG
  end

  def test_smaller_length_datablock
    incorrect_length = value.length - 4
    msg = data_block_length_error_msg incorrect_length, value
    assert_send_set key, flags, exptime, value, msg, incorrect_length

    assert_get key, Memcached::END_MSG
  end

  # Invalid command name error

  def test_invalid_command_name
    command_name = 'invalid_command_name'
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_empty_request_line
    socket.puts Memcached::CMD_ENDING.to_s
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_empty_command_name
    command_name = ''
    socket.puts "#{command_name} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_case_sensitive_command_name_upcase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.upcase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end

  def test_case_sensitive_command_name_titlecase
    socket.puts "#{Memcached::REPLACE_CMD_NAME.titlecase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    assert_get key, Memcached::END_MSG
  end
end
