# "prepend": means "add this data to an existing key before existing data".
# "append": means "add this data to an existing key after existing data".

require_relative "../../test_helper"

# Unit test for Memcached::Server class
class ServerPreAppendTest < BaseTest
  ###########     Append     ###########
  include Memcached::Mixin
  def test_simple_append
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, new_value.length, false, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, (value + new_value).length, value + new_value
    assert_equal expected_msg, read_reply(3)
  end

  def test_missing_key_append
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_value_append
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    append_value = ''
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, append_value.length, false, append_value, false
    assert_equal Memcached::STORED_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_no_reply_append
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    no_reply = true
    new_flags = flags + 8
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, new_flags, exptime, new_value.length, false, new_value, no_reply

    send_get_cmd key
    expected_msg = expected_get_response key, flags, (value + new_value).length, value + new_value # flags ignored for append commands
    assert_equal expected_msg, read_reply(3)
  end

  ###########     Prepend     ###########

  def test_simple_prepend
    v2 = "end"
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, v2.length, false, v2, false
    assert_equal Memcached::STORED_MSG, read_reply

    v1 = "start"
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, v1.length, false, v1, false
    assert_equal Memcached::STORED_MSG, read_reply
    
    # Get the item and assert reply
    send_get_cmd key
    expected_msg = expected_get_response key, flags, (v1 + v2).length, v1 + v2
    assert_equal expected_msg, read_reply(3)
  end

  def test_missing_key_prepend
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_value_prepend
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    new_value = ''
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, new_value.length, false, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_no_reply_prepend
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    no_reply = true
    new_flags = flags + 4
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, new_flags, exptime, new_value.length, false, new_value, true

    # Get the item and assert reply
    send_get_cmd key
    expected_msg = expected_get_response key, flags, (new_value + value).length, new_value + value # flags ignored for prepend commands
    assert_equal expected_msg, read_reply(3)
  end

  ###########     Test invalid parameters     ###########

  def test_invalid_length_parameter_prepend
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    smaller_length = new_value.length - 3
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, smaller_length, false, new_value, false

    excepted_reply = data_block_length_error_msg smaller_length, new_value
    assert_equal excepted_reply, read_reply

    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_invalid_length_parameter_append
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    smaller_length = new_value.length - 3
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, smaller_length, false, new_value, false
    
    excepted_reply = data_block_length_error_msg smaller_length, new_value
    assert_equal excepted_reply, read_reply

    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_value_too_long_prepend
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Prepending the existing value exceeds max length
    v2 = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 1)

    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, v2.length, false, v2, false
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_value_too_long_append
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Appending the existing value exceeds max length
    v2 = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 1)

    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, v2.length, false, v2, false
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end
end

