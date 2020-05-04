
require_relative "../test_helper"

class SetTest < BaseTest
  def test_set_simple
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3
  end

  def test_set_empty_key
    key = ''
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, read_reply
  end

  def test_set_empty_value
    value = ''
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3
  end

  def test_set_no_reply
    no_reply = true
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, no_reply)

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3
  end

  #### Test control characters included in value
  # Unstructured data is terminated by \r\n, even though \r, \n or any other 8-bit characters may also appear inside the data
  
  def test_set_value_with_control_chars_1
    value = "val\r\nwith\r\ntermination\r\nchars"

    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3 + value.count("\n")
  end

  def test_set_value_with_control_chars_2
    value = "value\twith\b\acontrol\nchars"
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd(key)
    assert_equal expected_get_response(key, flags, value.length, value), read_reply 3
  end

  def test_set_value_with_control_chars_3
    value = "\r\n"

    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3 + value.count("\n")
  end

  def test_set_value_with_control_chars_tab
    value = "\t"

    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3
  end

  def test_set_value_with_control_chars_5
    value = "\t\0\b\n\n\n"

    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3 + value.count("\n")
  end

  def test_set_value_with_multiple_ending_chars
    value = "\r\nmemcached\r\nmemcached\r\n\r\nmemcached\r\nmemcached\r\n\r\n\r\n"

    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get = expected_get_response key, flags, value.length, value
    assert_equal expected_get, read_reply 3 + value.count("\n")
  end

  # ####     Test invalid parameters

  # #=> Key

  def test_set_key_with_whitespaces
    key = 'key with whitespaces'
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_with_control_characters_1
    key1 = "key\0withnull"
    send_storage_cmd(Memcached::SET_CMD_NAME, key1, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_with_control_characters_2
    key2 = "key\twith\ttabs"
    send_storage_cmd(Memcached::SET_CMD_NAME, key2, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_with_control_characters_3
    key3 = "\a\akey\bwith\vmultiple_control\f_chars"
    send_storage_cmd(Memcached::SET_CMD_NAME, key3, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_with_control_characters_4
    key = "\nkey\nwith\nmultiple_new_lines\n"
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply 2

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Flags

  def test_set_negative_flags
    flags = -4
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_flags_exceeds_max
    # flags bigger than the maximum 16-bit integer
    flags = FLAGS_LIMIT + 1
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_flags
    flags = 'abc'
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_empty_flags
    flags = ''
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Exptime

  def test_set_string_exptime_without_digits
    exptime = 'test_exptime'
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_empty_exptime
    exptime = ''
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  # #=> Length

  def test_set_negative_length
    negative_length = -6
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, negative_length, false, value, false)
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_string_length_without_digits
    length_without_digits = 'test_length'
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, length_without_digits, false, value, false)
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_nil_length
    length = ''
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, length, false, value, false)
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_incorrect_length_smaller
    # Smaller 'length' than the actual length of the value
    incorrect_length = value.length-4
    
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, incorrect_length, false, value, false)
    assert_equal Memcached::CLIENT_ERROR + "<length> (#{incorrect_length}) is not equal to the length of the item's data_block (#{value.length})" + Memcached::CMD_ENDING, read_reply 
  
    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  ##### Test set error responses

  def test_set_value_too_long
    value = 'v' * (Memcached::MAX_DATA_BLOCK_LENGTH + 1)

    send_storage_cmd("#{Memcached::SET_CMD_NAME}", key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_key_too_long
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    send_storage_cmd(Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false)
    assert_equal Memcached::KEY_TOO_LONG_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_bad_termination_request_line
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply 2

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_bad_termination_datablock
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length}" + Memcached::CMD_ENDING
    socket.puts "#{value}$$"
    assert_equal Memcached::CMD_TERMINATION_MSG, reply_reply 2

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_set_noreply_syntax_error
    wrong_syntax_no_reply = 'norep'

    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{wrong_syntax_no_reply}" + Memcached::CMD_ENDING
    socket.puts "#{value}" + Memcached::CMD_ENDING
    assert_equal Memcached::CLIENT_ERROR + "\"#{Memcached::NOREPLY}\" was expected as the 6th argument, but \"#{wrong_syntax_no_reply}\" was received" + Memcached::CMD_ENDING, read_reply
  
    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end
end
