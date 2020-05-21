# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class

# "cas" is a check and set operation which means "store this data
#       but only if no one else has updated since I last fetched it."

class ServerCasTest < ServerTestHelper
  include Memcached::Mixin

  def send_cas_cmd(key, flags, exptime, length, value, unique_cas_key, noreply = false)
    request = "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{length} #{unique_cas_key}"
    request += " #{Memcached::NO_REPLY}" if noreply
    request += Memcached::CMD_ENDING

    socket_puts request, value
  end

  def assert_send_cas(key, flags, exptime, value, unique_cas_key, msg = Memcached::STORED_MSG, length = value.length, noreply = false)
    send_cas_cmd key, flags, exptime, length, value, unique_cas_key, noreply
    assert_equal msg, read_reply
  end

  ###########     Test cas     ###########

  def test_simple_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_flags = flags * 2
    assert_send_cas key, new_flags, exptime, new_value, cas_key

    # Get the stored item with cas update
    assert_multine_gets key, new_flags, new_value, (cas_key + 1)
  end

  def test_exists_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_flags = flags + 3
    assert_send_cas key, new_flags, exptime, new_value, (cas_key + 10), Memcached::EXISTS_MSG

    # Get the initial item without updates
    assert_multine_gets key, flags, value, cas_key
  end

  def test_not_found_cas
    assert_send_cas key, flags, exptime, value, cas_key, Memcached::NOT_FOUND_MSG
    assert_get key, Memcached::END_MSG, true
  end

  def test_no_reply_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_flags = flags + 2
    send_cas_cmd key, new_flags, exptime, new_value.length, new_value, cas_key, true

    # Get the stored item with cas update
    assert_multine_gets key, new_flags, new_value, (cas_key + 1)
  end

  # Test expiration time

  def test_exptime_cas
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Cas expired in Memcached::PURGE_EXPIRED_KEYS_FREQUENCY_SECS - 5
    cas_key = get_cas_key key
    new_flags = flags + 4
    exptime = Memcached::PURGE_EXPIRED_KEYS_FREQUENCY_SECS - 5
    send_cas_cmd key, new_flags, exptime, new_value.length, new_value, cas_key, true

    # Check the item is not yet expired
    assert_multine_get key, new_flags, new_value

    wait_for_purge_exec

    # Get expired item
    assert_get key, Memcached::END_MSG, true
  end

  def test_expired_cas
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Cas an expired item
    cas_key = get_cas_key key
    send_cas_cmd key, flags, -1, new_value.length, new_value, cas_key, true

    # Get expired item
    assert_get key, Memcached::END_MSG, true
  end

  # Test invalid parameters

  def test_negative_cas_unique_key
    assert_send_cas key, flags, exptime, value, -2, Memcached::CAS_KEY_TYPE_MSG
    assert_get key, Memcached::END_MSG, true
  end

  def test_exceeds_max_cas_unique_key
    cas_key = Memcached::CAS_KEY_LIMIT + 1
    assert_send_cas key, flags, exptime, value, cas_key, Memcached::CAS_KEY_TYPE_MSG
    assert_get key, Memcached::END_MSG, true
  end

  def test_string_cas_unique_key
    cas_key = 'unique_cas_key'
    assert_send_cas key, flags, exptime, value, cas_key, Memcached::CAS_KEY_TYPE_MSG
    assert_get key, Memcached::END_MSG, true
  end

  def test_empty_string_cas_unique_key
    cas_key = nil
    assert_send_cas key, flags, exptime, value, cas_key, Memcached::TOO_FEW_ARGUMENTS_MSG
    assert_get key, Memcached::END_MSG, true
  end

  def test_noreply_syntax_error_cas
    no_reply = 'norep'

    req = "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{cas_key} #{no_reply}#{Memcached::CMD_ENDING}"
    socket_puts req, value

    excepted_reply = no_reply_syntax_error_msg no_reply, Memcached::CAS_CMD_PARAMETERS_MAX_LENGTH
    assert_equal excepted_reply, read_reply

    assert_get key, Memcached::END_MSG, true
  end
end
