# "prepend": means "add this data to an existing key before existing data".
# "append": means "add this data to an existing key after existing data".

require_relative "../test_helper"

class PreAppendTest < BaseTest
  ###########     Append     ###########

  def test_simple_append
    v1 = "start"
    send_storage_cmd("set", key, 2, 3000, v1.length, false, v1, false)
    assert_equal Memcached::STORED_MSG, read_reply

    v2 = "end"
    send_storage_cmd("append", key, 2, 3000, v2.length, false, v2, false)
    assert_equal Memcached::STORED_MSG, read_reply
    
    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, (v1+v2).length, v1+v2), reply
  end

  def test_missing_key_append
    value = "end"
    send_storage_cmd("append", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_empty_value_append
    send_storage_cmd("set", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_storage_cmd("append", key, 2, 400, 0, false, nil, false)
    assert_equal Memcached::STORED_MSG, read_reply
    
    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length, value), reply
  end

  def test_no_reply_append
    send_storage_cmd("set", key, 3, 300, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    value2 = "tail"
    # Send "append" command with "noreply"
    send_storage_cmd("append", key, 4, 400, value2.length, false, value2, true)

    # Get the item and assert reply
    reply = send_get_cmd(key)
    
    # Note flags are ignored in append/prepend cmds
    assert_equal expected_get_response(key, 3, (value + value2).length, value + value2), reply
  end

  ###########     Prepend     ###########

  def test_simple_prepend
    v2 = "end"
    send_storage_cmd("set", key, 2, 3000, v2.length, false, v2, false)
    assert_equal Memcached::STORED_MSG, read_reply

    v1 = "start"
    send_storage_cmd("prepend", key, 2, 3000, v1.length, false, v1, false)
    assert_equal Memcached::STORED_MSG, read_reply
    
    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, (v1 + v2).length, v1 + v2), reply
  end

  def test_missing_key_prepend
    v1 = "start"
    send_storage_cmd("prepend", key, 2, 3000, v1.length, false, v1, false)
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_empty_value_prepend
    send_storage_cmd("set", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    send_storage_cmd("prepend", key, 2, 400, 0, false, nil, false)
    assert_equal Memcached::STORED_MSG, read_reply
    
    # Get the item and assert reply
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length, value), reply
  end

  def test_no_reply_prepend
    send_storage_cmd("set", key, 3, 300, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    value2 = "new_value"
    # Send "prepend" command with <noreply>
    send_storage_cmd("prepend", key, 4, 400, value2.length, false, value2, true)

    # Get the item and assert reply
    # Note flags are ignored in append/prepend cmds
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 3, (value2 + value).length, value2 + value), reply
  end

  ###########     Test invalid parameters     ###########

  def test_wrong_length_parameter
    send_storage_cmd("set", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Try prepending with smaller length parameter than the actual length
    v1 = "start"
    send_storage_cmd("prepend", key, 2, 3000, v1.length-5, false, v1, false)
    assert_equal "CLIENT_ERROR <length> (#{v1.length-5}) is not equal to the length of the item's data_block (#{v1.length})\r\n", read_reply
    
    # Try appending with smaller length parameter than the actual length
    v2 = "end"
    send_storage_cmd("append", key, 2, 3000, v2.length-1, false, v2, false)
    assert_equal "CLIENT_ERROR <length> (#{v2.length-1}) is not equal to the length of the item's data_block (#{v2.length})\r\n", read_reply

    # Get the item and assert reply without changes
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length, value), reply
  end

  def test_value_too_long_prepend
    send_storage_cmd("set", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    #Prepend / append a value that, combined with the existing value, exceeds max length
    v2 = "b" * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 1)
    
    send_storage_cmd("prepend", key, 2, 3000, v2.length, false, v2, false)
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply
    
    # Get the item and assert reply without changes
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length, value), reply
  end

  def test_value_too_long_append
    send_storage_cmd("set", key, 2, 3000, value.length, false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    #Prepend / append a value that, combined with the existing value, exceeds max length
    v2 = "b" * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 200)

    send_storage_cmd("append", key, 2, 3000, v2.length, false, v2, false)
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply
    
    # Get the item and assert reply without changes
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 2, value.length, value), reply
  end

  def test_case_sensitive_prepend_upcase
    socket.puts "#{Memcached::PREPEND_CMD_NAME.upcase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_case_sensitive_prepend_titlecase
    socket.puts "#{Memcached::PREPEND_CMD_NAME.titlecase} #{key} #{flags} #{exptime} #{value.length}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end
end

