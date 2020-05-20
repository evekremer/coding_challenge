# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class

# "cas" is a check and set operation which means "store this data
#       but only if no one else has updated since I last fetched it."

class ServerCasTest < BaseTest
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

  def assert_multine_gets(key, flags, value, cas_key, times = 3)
    send_get_cmd key, true
    expected_msg = expected_get_response key, flags, value.length, value, cas_key
    assert_equal expected_msg, read_reply(times)
  end

  def test_simple_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_flags = flags * 2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, cas_key, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the stored item with cas update
    assert_multine_gets key, new_flags, new_value, (cas_key + 1)
  end

  def test_exists_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_cas_key = cas_key + 1
    new_flags = flags + 3
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, new_cas_key, new_value, false
    assert_equal Memcached::EXISTS_MSG, read_reply

    # Get the initial item without updates
    assert_multine_gets key, flags, value, (cas_key + 1)
  end

  def test_not_found_cas
    cas_key = 5
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::NOT_FOUND_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_no_reply_cas
    assert_send_set key, flags, exptime, value

    cas_key = get_cas_key key
    new_flags = flags + 2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, cas_key, new_value, true

    # Get the stored item with cas update
    assert_multine_gets key, new_flags, new_value, (cas_key + 1)
  end

  #     Test invalid parameters

  def test_negative_cas_unique_key
    cas_key = -2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_exceeds_max_cas_unique_key
    cas_key = Memcached::CAS_KEY_LIMIT + 1
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_string_cas_unique_key
    cas_key = 'unique_cas_key'
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_empty_string_cas_unique_key
    cas_key = nil
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_exptime_cas
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Cas with exptime = 3 seconds
    cas_key = get_cas_key key
    new_flags = flags + 4
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, 3, new_value.length, cas_key, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    assert_multine_get key, new_flags, new_value

    wait_for_purge_exec

    # Get expired item
    assert_get key, Memcached::END_MSG, true
  end

  def test_expired_cas
    # Set item that never expires
    assert_send_set key, flags, 0, value

    # Cas expired item
    cas_key = get_cas_key key
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, -1, new_value.length, cas_key, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Get expired item
    assert_get key, Memcached::END_MSG, true
  end

  # Test cas error responses

  def test_noreply_syntax_error_cas
    no_reply = 'norep'

    req = "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{cas_key} #{no_reply}#{Memcached::CMD_ENDING}"
    socket_puts req, value

    excepted_reply = no_reply_syntax_error_msg no_reply, Memcached::CAS_CMD_PARAMETERS_MAX_LENGTH
    assert_equal excepted_reply, read_reply

    assert_get key, Memcached::END_MSG, true
  end

  def test_invalid_cmd_termination
    socket.puts "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{cas_key} #{Memcached::NO_REPLY}\n#{Memcached::CMD_ENDING}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    assert_get key, Memcached::END_MSG, true
  end
end
