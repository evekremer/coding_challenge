require_relative "../../test_helper"

# Unit test for Memcached::Server class
class ServerGetGetsTest < BaseTest

  ###########     Get     ###########

  def test_simple_multi_get
    expected_reply = ""
    keys = Array.new

    # Set multiple values
    10.times{ |i|
      key = "#{key}#{i}"
      send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true
      expected_reply += expected_get_response key, flags, value.length, value, false, true
      keys[i] = key
    }
    expected_reply += Memcached::END_MSG

    # Get multiple values for stored keys
    send_get_multi_keys keys
    assert_equal expected_reply, read_reply((keys.length * 2) + 1)
  end
  
  def test_get_empty_key
    key = ''
    send_get_cmd key
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply
  end

  def test_all_missing_multi_get
    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_all_empty_value_multi_get
    expected_reply = ""
    keys = Array.new
    value = ''

    # Set multiple empty values
    10.times{ |i|
      key = "#{key}#{i}"
      send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true
      expected_reply += expected_get_response key, flags, value.length, value, false, true
      keys[i] = key
    }
    expected_reply += Memcached::END_MSG

    # Get multiple empty values for stored keys
    send_get_multi_keys keys
    assert_equal expected_reply, read_reply((keys.length * 2) + 1)
  end

  def test_some_missing_keys_multi_get
    send_storage_cmd Memcached::SET_CMD_NAME, "#{key}1", flags, exptime, value.length, false, value
    read_reply

    send_storage_cmd Memcached::SET_CMD_NAME, "#{key}3", flags + 1, exptime, value.length, false, value
    read_reply

    exp_reply_multi = expected_get_response "#{key}1", flags, value.length, value, false, true
    exp_reply_multi += expected_get_response "#{key}3", flags + 1, value.length, value, false

    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys
    assert_equal exp_reply_multi, read_reply(5)
  end

  def test_key_too_long_get
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    send_get_cmd key
    assert_equal Memcached::KEY_TOO_LONG_MSG, read_reply
  end

  def test_get_expired
    exptime = -6
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  ###########     Gets     ###########

  def test_simple_multi_gets
    expected_reply = ""
    keys = Array.new

    # Set multiple values
    10.times{ |i|
      key = "#{key}#{i}"
      send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true
      expected_reply += expected_get_response key, flags, value.length, value, get_cas_key(key), true
      keys[i] = key
    }
    expected_reply += Memcached::END_MSG

    # Get multiple values for stored keys
    send_get_multi_keys keys, true
    assert_equal expected_reply, read_reply((keys.length * 2) + 1)
  end

  def test_gets_empty_key
    key = ''
    send_get_cmd key, true
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply
  end

  def test_all_missing_multi_gets
    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_all_empty_value_multi_gets
    expected_reply = ""
    keys = Array.new
    value = ''

    # Set multiple empty values
    10.times{ |i|
      key = "#{key}#{i}"
      send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true
      expected_reply += expected_get_response key, flags, value.length, value, get_cas_key(key), true
      keys[i] = key
    }
    expected_reply += Memcached::END_MSG

    # Gets multiple empty values for stored keys
    send_get_multi_keys keys, true
    assert_equal expected_reply, read_reply((keys.length * 2) + 1)
  end

  def test_some_missing_keys_multi_gets
    send_storage_cmd Memcached::SET_CMD_NAME, "#{key}1", flags, exptime, value.length, false, value
    read_reply

    send_storage_cmd Memcached::SET_CMD_NAME, "#{key}3", flags + 1, exptime, value.length, false, value
    read_reply

    exp_reply_multi = expected_get_response "#{key}1", flags, value.length, value, get_cas_key("#{key}1"), true
    exp_reply_multi += expected_get_response "#{key}3", flags + 1, value.length, value, get_cas_key("#{key}3")

    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal exp_reply_multi, read_reply(5)
  end

  def test_key_too_long_gets
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    send_get_cmd key, true
    assert_equal Memcached::KEY_TOO_LONG_MSG, read_reply
  end

  def test_gets_expired
    exptime = -6
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, true

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end
end
