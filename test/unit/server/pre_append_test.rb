# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
# "append": means "add this data to an existing key after existing data".
# "prepend": means "add this data to an existing key before existing data".
class ServerPreAppendTest < ServerTestHelper
  include Memcached::Mixin

  ###########     Test append     ###########

  def test_simple_append
    assert_send_set key, flags, exptime, value
    assert_send_append key, flags, exptime, new_value
    assert_multine_get key, flags, (value + new_value)
  end

  def test_missing_key_append
    assert_send_append key, flags, exptime, value, Memcached::NOT_STORED_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_empty_value_append
    assert_send_set key, flags, exptime, value
    assert_send_append key, flags, exptime, ''
    assert_multine_get key, flags, value
  end

  def test_no_reply_append
    assert_send_set key, flags, exptime, value

    new_flags = flags + 8
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, new_flags, exptime, new_value.length, new_value, true

    # flags ignored for append commands
    assert_multine_get key, flags, (value + new_value)
  end

  def test_value_too_long_append
    assert_send_set key, flags, exptime, value

    # Appending the existing value exceeds max length
    v = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 1)
    assert_send_append key, flags, exptime, v, Memcached::DATA_BLOCK_TOO_LONG_MSG

    assert_multine_get key, flags, value
  end

  ###########     Test prepend     ###########

  def assert_send_prepend(key, flags, exptime, value, msg = Memcached::STORED_MSG, length = value.length)
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, flags, exptime, length, value
    assert_equal msg, read_reply
  end

  def test_simple_prepend
    v2 = 'end'
    assert_send_set key, flags, exptime, v2

    v1 = 'start'
    assert_send_prepend key, flags, exptime, v1

    assert_multine_get key, flags, (v1 + v2)
  end

  def test_missing_key_prepend
    assert_send_prepend key, flags, exptime, value, Memcached::NOT_STORED_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_empty_value_prepend
    assert_send_set key, flags, exptime, value
    assert_send_prepend key, flags, exptime, ''
    assert_multine_get key, flags, value
  end

  def test_no_reply_prepend
    assert_send_set key, flags, exptime, value

    new_flags = flags + 4
    send_storage_cmd Memcached::PREPEND_CMD_NAME, key, new_flags, exptime, new_value.length, new_value, true

    # flags ignored for prepend commands
    assert_multine_get key, flags, (new_value + value)
  end

  def test_value_too_long_prepend
    assert_send_set key, flags, exptime, value

    # Prepending the existing value exceeds max length
    v = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - value.length + 1)
    assert_send_prepend key, flags, exptime, v, Memcached::DATA_BLOCK_TOO_LONG_MSG

    assert_multine_get key, flags, value
  end
end
