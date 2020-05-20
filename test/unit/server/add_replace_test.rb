# frozen_string_literal: true

# "add": means "store this data,
#       but only if the server *doesn't* already hold data for this key".
# "replace" means "store this data,
#       but only if the server *does* already hold data for this key".

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
class ServerAddReplaceTest < BaseTest
  ###########     Add     ###########

  def assert_send_add(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::ADD_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end

  def test_simple_add
    assert_send_add key, flags, exptime, value
    assert_multine_get key, flags, value
  end

  def test_existing_key_add
    assert_send_set key, flags, exptime, value
    assert_send_add key, (flags + 1), exptime, new_value, Memcached::NOT_STORED_MSG
    assert_multine_get key, flags, value
  end

  def test_exptime_add
    assert_send_add key, flags, 3, value

    assert_multine_get key, flags, value
    wait_for_purge_exec
    assert_get key, Memcached::END_MSG
  end

  def test_expired_add
    assert_send_add key, flags, -1, value
    assert_get key, Memcached::END_MSG
  end

  def test_no_reply_add
    send_storage_cmd Memcached::ADD_CMD_NAME, key, flags, exptime, value.length, value, true
    assert_multine_get key, flags, value
  end

  ###########     Replace     ###########

  def assert_send_replace(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end

  def test_simple_replace
    assert_send_set key, flags, exptime, value

    new_flags = flags + 6
    assert_send_replace key, new_flags, exptime, new_value

    # Get stored item with updated value
    assert_multine_get key, new_flags, new_value
  end

  def test_missing_key_replace
    assert_send_set key, flags, exptime, value, Memcached::NOT_STORED_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_exptime_replace
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Replace for item that expires in 3 seconds
    new_flags = flags + 3
    assert_send_replace key, new_flags, 3, new_value

    assert_multine_get key, new_flags, new_value
    wait_for_purge_exec
    assert_get key, Memcached::END_MSG
  end

  def test_expired_replace
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Replace for item that immediatelly expires
    assert_send_replace key, flags, -1, value

    assert_get key, Memcached::END_MSG
  end

  def test_no_reply_replace
    assert_send_set key, flags, exptime, value
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, flags, exptime, new_value.length, new_value, true
    assert_multine_get key, flags, new_value
  end
end
