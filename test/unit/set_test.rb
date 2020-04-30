
require_relative "../test_helper"

class SetTest < BaseTest
  def test_simple_set
    send_storage_cmd("set", key, 2, 6000, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length(), value), reply
  end

  def test_nil_key_set_1
    request = "set 3 300 5\r\n"
    socket.puts request
    socket.puts "value\r\n"
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply
  end

  def test_nil_key_set_2
    send_storage_cmd("set", nil, 4, 800, value.length(), false, value, false)
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, read_reply
  end

  def test_empty_value_set
    # set with value = nil and length = 0
    send_storage_cmd("set", key, 7, 800, 0, false, nil, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item with empty value
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 7, 0, nil), reply
  end

  def test_no_reply_set
    # Send "set" command with <noreply>
    send_storage_cmd("set", key, 3, 300, value.length(), false, value, true)

    # Get the item
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 3, value.length(), value), reply
  end

  #### Test control characters included in value
  # Unstructured data is terminated by \r\n, even though \r, \n or any other 8-bit characters may also appear inside the data
  
  def test_value_with_control_chars_set_1
    value = "val\r\nwith\r\ntermination\r\nchars"

    send_storage_cmd("set", key, 1, 800, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 1, value.length(), value), reply
  end

  def test_value_with_control_chars_set_2
    value = "value\twith\b\acontrol\nchars"

    send_storage_cmd("set", key, 9, 800, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 9, value.length(), value), reply
  end

  def test_value_with_control_chars_set_3
    value = "\r\n"

    send_storage_cmd("set", key, 3, 800, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 3, value.length(), value), reply
  end

  def test_value_with_control_chars_set_4
    value = "\t"

    send_storage_cmd("set", key, 2, 800, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 2, value.length(), value), reply
  end

  def test_value_with_control_chars_set_5
    value = "\t\0\b\n\n\n\r\n"

    send_storage_cmd("set", key, 5, 800, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 5, value.length(), value), reply
  end

  def test_value_with_multiple_ending_chars
    value = "\r\nmemcached\r\nmemcached\r\n\r\nmemcached\r\nmemcached\r\n\r\n\r\n\r\n"

    send_storage_cmd("set", key, 6, 600, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the item
    reply = send_get_cmd(key, false, value.length())
    assert_equal expected_get_response(key, 6, value.length(), value), reply
  end

  # ####     Test invalid parameters

  # #=> Key

  def test_key_with_whitespaces
    key = "key with whitespaces"

    send_storage_cmd("set", key, 9, 43782, value.length(), false, value, false)
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_key_with_control_characters_1
    key1 = "key\0withnull"
    send_storage_cmd("set", key1, 9, 4382, value.length(), false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_key_with_control_characters_2
    key2 = "key\twith\ttabs"
    send_storage_cmd("set", key2, 9, 4382, value.length(), false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_key_with_control_characters_3
    key3 = "\a\akey\bwith\vmultiple_control\f_chars"
    send_storage_cmd("set", key3, 9, 4382, value.length(), false, value, false)
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_key_with_control_characters_4
    key4 = "\nkey\nwith\nmultiple_new_lines\n"
    send_storage_cmd("set", key4, 9, 4382, value.length(), false, value, false)
    reply = read_reply(2)
    assert_equal Memcached::CMD_TERMINATION_MSG, reply
  end

  # #=> Flags

  def test_negative_flags_set
    send_storage_cmd("set", key, -4, 300, value.length(), false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_flags_exceeds_max_set
    # flags bigger than the maximum 16-bit integer
    send_storage_cmd("set", key, (2**16)+1, 300, value.length(), false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_string_flags_set
    send_storage_cmd("set", key, "abc", 300, value.length(), false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_nil_flags_set
    send_storage_cmd("set", key, nil, 300, value.length(), false, value, false)
    assert_equal Memcached::FLAGS_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  # #=> Exptime

  def test_string_exptime_set
    send_storage_cmd("set", key, 3, "test_exptime", value.length(), false, value, false)
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_nil_exptime_set
    send_storage_cmd("set", key, 3, nil, value.length(), false, value, false)
    assert_equal Memcached::EXPTIME_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  # #=> Length

  def test_negative_length_set
    send_storage_cmd("set", key, 3, 300, -6, false, value, false)
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_string_length_set
    send_storage_cmd("set", key, 3, 300, "test_length", false, value, false)
    assert_equal Memcached::LENGTH_TYPE_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_nil_length_set
    send_storage_cmd("set", key, 3, 300, nil, false, value, false)
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  # def test_incorrect_length_bigger_set
  #   # Bigger 'length' than the actual length of the value
  #   send_storage_cmd("set", key, 2, 3000, value.length()+5, false, value, false)
  #   assert_equal "CLIENT_ERROR <length> (#{value.length()+5}) is not equal to the length of the item's data_block (#{value.length()})\r\n", read_reply

  #   reply = send_get_cmd(key)
  #   assert_equal Memcached::END_MSG, reply
  # end

  def test_incorrect_length_smaller_set
    # Smaller 'length' than the actual length of the value
    send_storage_cmd("set", key, 2, 3000, value.length()-4, false, value, false)
    assert_equal "CLIENT_ERROR <length> (#{value.length()-4}) is not equal to the length of the item's data_block (#{value.length()})\r\n", read_reply 

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end
end
