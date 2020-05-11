
require_relative "../../test_helper"

# Unit test for Memcached::Server class
class ServerSetTest < BaseTest

  include Memcached::Mixin

  def test_set_simple
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3)
  end

  def test_set_empty_key
    key = ''
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply
  end

  def test_set_empty_value
    value = ''
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3)
  end

  def test_set_no_reply
    no_reply = true
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, no_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3)
  end

  #### Test control characters included in data_block
  # Unstructured data is terminated by \r\n, even though \r, \n or any other 8-bit characters may also appear inside the data
  
  def test_set_value_termination_chars
    value = "\r\nval\r\nwith\r\ntermination\r\nchars\r\n\r\n"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3 + value.count("\n"))
  end

  def test_set_value_only_termination_chars
    value = "\r\n"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3 + value.count("\n"))
  end

  def test_set_value_with_control_chars
    value = "value\twith\b\acontrol\nchars"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3 + value.count("\n"))
  end

  def test_set_value_only_newline_control_char
    value = "value with newline\n"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3 + value.count("\n"))
  end

  def test_set_value_only_cr_control_char
    value = "value with carrige return\r"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply(3)
  end

  # ####     Test invalid parameters

  # #=> Key

  def test_set_key_with_whitespaces_1
    key = 'key with whitespaces'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_with_whitespaces_2
    key = '   key   '
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, read_reply
  end

  def test_set_key_control_char_null
    key1 = "key\0withnull"
    send_storage_cmd Memcached::SET_CMD_NAME, key1, flags, exptime, value.length, false, value, false
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_control_chars_tab
    key2 = "key\twith\ttabs"
    send_storage_cmd Memcached::SET_CMD_NAME, key2, flags, exptime, value.length, false, value, false
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_multiple_control_char
    key3 = "\a\akey\bwith\vmultiple_control\f_chars"
    send_storage_cmd Memcached::SET_CMD_NAME, key3, flags, exptime, value.length, false, value, false
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_starts_with_request_termination
    key = "\r\nkey"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> \r\n" as the command request line
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply 

    send_get_cmd key
    #=> takes "<Memcached::GET_CMD_NAME> \r\n" as the command request line
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply
  end

  def test_set_key_control_chars_termination
    key = "memcached\r\nkey\r\n"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    
    # Server reads until the first ocurrance of \n
    #=> takes "<Memcached::SET_CMD_NAME> memcached\r\n" as the command request line
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply 

    send_get_cmd key
    #=> takes "<Memcached::GET_CMD_NAME> memcached\r\n" as the command request line
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Flags

  def test_set_negative_flags
    negative_flags = -4
    send_storage_cmd Memcached::SET_CMD_NAME, key, negative_flags, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_flags_exceeds_max
    # flags bigger than the maximum 16-bit integer
    too_big_flags = Memcached::FLAGS_LIMIT + 1
    send_storage_cmd Memcached::SET_CMD_NAME, key, too_big_flags, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_flags
    flags_without_digits = 'abc'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags_without_digits, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_with_digits_flags
    flags_with_digits = 'abc123'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags_with_digits, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_empty_flags
    empty_flags = ''
    send_storage_cmd Memcached::SET_CMD_NAME, key, empty_flags, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Exptime

  def test_set_string_exptime_with_digits
    exptime_with_digits = 'test_exptime_1234'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime_with_digits, value.length, false, value, false
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_empty_exptime
    empty_exptime = ''
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, empty_exptime, value.length, false, value, false
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_exptime_set
    exptime = 3
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_get_msg, read_reply(3)

    wait_for_purge_exec

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_expired
    exptime = -1
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Length

  def test_set_negative_length
    negative_length = -6
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, negative_length, false, value, false
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_length
    length_without_digits = 'test_length'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, length_without_digits, false, value, false
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_length_with_digits
    length_with_digits = 'test_length_1234'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, length_with_digits, false, value, false
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_empty_length
    empty_length = ''
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, empty_length, false, value, false
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_value_too_long
    too_long_value = 'v' * (Memcached::MAX_DATA_BLOCK_LENGTH + 1)
    send_storage_cmd "#{Memcached::SET_CMD_NAME}", key, flags, exptime, too_long_value.length, false, too_long_value, false
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_too_long
    too_long_key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    send_storage_cmd Memcached::SET_CMD_NAME, too_long_key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::KEY_TOO_LONG_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_noreply_syntax_error
    wrong_syntax_no_reply = 'norep'
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{wrong_syntax_no_reply}#{Memcached::CMD_ENDING}"
    socket.puts "#{value}#{Memcached::CMD_ENDING}"

    excepted_reply = no_reply_syntax_error_msg wrong_syntax_no_reply, Memcached::STORAGE_CMD_PARAMETERS_MAX_LENGTH
    assert_equal excepted_reply, read_reply
  
    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end
end
