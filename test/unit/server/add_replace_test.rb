# "add": means "store this data, but only if the server *doesn't* already hold data for this key".
# "replace" means "store this data, but only if the server *does* already hold data for this key".

require_relative "../test_helper"

class ServerAddReplaceTest < BaseTest

  ###########     Add     ###########

  def test_simple_add
    send_storage_cmd Memcached::ADD_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply
    
    send_get_cmd key
    expected_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_msg, read_reply(3)
  end

  def test_existing_key_add
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    new_flags = flags + 1
    send_storage_cmd Memcached::ADD_CMD_NAME, key, new_flags, exptime, new_value.length, false, new_value, false
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_get_msg, read_reply(3)
  end

  def test_exptime_add
    exptime = 3
    send_storage_cmd Memcached::ADD_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_get_msg, read_reply(3)

    wait_for_purge_exec

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_no_reply_add
    no_reply = true
    send_storage_cmd Memcached::ADD_CMD_NAME, key, flags, exptime, value.length, false, value, no_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, flags, value.length, value
    assert_equal expected_get_msg, read_reply(3)
  end

  ###########     Replace     ###########

  def test_simple_replace
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, 100, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    new_flags = flags + 6
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, new_flags, 6000, new_value.length, false, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Get stored item with updated value
    send_get_cmd key
    expected_get_msg = expected_get_response key, new_flags, new_value.length, new_value
    assert_equal expected_get_msg, read_reply(3)
  end

  def test_missing_key_replace
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, 5, 6000, value.length, false, value, false
    assert_equal Memcached::NOT_STORED_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_exptime_replace
    # Set item that never expires
    exptime = 0
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Replace for item that expires in 3 seconds
    new_flags = flags + 3
    exptime = 3
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, new_flags, exptime, new_value.length, false, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, new_flags, new_value.length, new_value
    assert_equal expected_get_msg, read_reply(3)

    wait_for_purge_exec
    
    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_no_reply_replace
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    no_reply = true
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, flags, exptime, new_value.length, false, new_value, no_reply

    send_get_cmd key
    expected_get_msg = expected_get_response key, flags, new_value.length, new_value
    assert_equal expected_get_msg, read_reply(3)
  end
end