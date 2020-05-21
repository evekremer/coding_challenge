# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
class ServerGetGetsTest < ServerTestHelper
  def setup
    @expected_reply_get = ''
    @expected_reply_gets = ''
    @keys = []

    10.times do |i|
      key = "#{key}#{i}"
      send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, value, true
      @expected_reply_get += expected_get_response key, flags, value.length, value, false, true
      @expected_reply_gets += expected_get_response key, flags, value.length, value, get_cas_key(key), true
      @keys[i] = key
    end
    @expected_reply_get += Memcached::END_MSG
    @expected_reply_gets += Memcached::END_MSG
  end

  def test_simple_multi_get
    send_get_multi_keys @keys
    assert_equal @expected_reply_get, read_reply((@keys.length * 2) + 1)
  end

  def test_simple_multi_gets
    send_get_multi_keys @keys, true
    assert_equal @expected_reply_gets, read_reply((@keys.length * 2) + 1)
  end

  def test_get_empty_key
    assert_get '', Memcached::TOO_FEW_ARGUMENTS_MSG, true
  end

  def test_gets_empty_key
    assert_get '', Memcached::TOO_FEW_ARGUMENTS_MSG, true
  end

  def test_all_missing_multi_get
    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_all_missing_multi_gets
    keys = ["#{key}1", "#{key}2", "#{key}3", "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_all_empty_value_multi
    value = expected_reply_get = expected_reply_gets = ''
    # Set multiple empty values
    10.times do |i|
      send_storage_cmd Memcached::REPLACE_CMD_NAME, @keys[i], flags, exptime, value.length, value, true
      expected_reply_get += expected_get_response @keys[i], flags, value.length, value, false, true
      expected_reply_gets += expected_get_response @keys[i], flags, value.length, value, get_cas_key(@keys[i]), true
    end
    expected_reply_get += Memcached::END_MSG
    expected_reply_gets += Memcached::END_MSG

    # Get/gets multiple empty values for stored keys
    send_get_multi_keys @keys
    assert_equal expected_reply_get, read_reply((@keys.length * 2) + 1)

    # Gets multiple empty values for stored keys
    send_get_multi_keys @keys, true
    assert_equal expected_reply_gets, read_reply((@keys.length * 2) + 1)
  end

  def test_some_missing_keys_multi_get
    value = 'value_setup'
    exp_reply_multi = expected_get_response @keys[3], flags, value.length, value, false, true
    exp_reply_multi += expected_get_response @keys[6], flags, value.length, value

    keys = [@keys[3], "#{key}3", @keys[6], "#{key}4", "#{key}5"]
    send_get_multi_keys keys
    assert_equal exp_reply_multi, read_reply(5)
  end

  def test_some_missing_keys_multi_gets
    value = 'value_setup'
    exp_reply_multi = expected_get_response @keys[0], flags, value.length, value, get_cas_key(@keys[0]), true
    exp_reply_multi += expected_get_response @keys[1], flags, value.length, value, get_cas_key(@keys[1])

    keys = [@keys[0], "#{key}3", @keys[1], "#{key}4", "#{key}5"]
    send_get_multi_keys keys, true
    assert_equal exp_reply_multi, read_reply(5)
  end

  def test_key_too_long_get
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    assert_get key, Memcached::KEY_TOO_LONG_MSG
  end

  def test_key_too_long_gets
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    assert_get key, Memcached::KEY_TOO_LONG_MSG, true
  end

  def test_get_expired
    assert_send_set key, flags, -7, value
    assert_get key, Memcached::END_MSG
  end

  def test_gets_expired
    assert_send_set key, flags, -7, value
    assert_get key, Memcached::END_MSG, true
  end
end
