#"cas" is a check and set operation which means "store this data but only if no one else has updated since I last fetched it."
require_relative "../test_helper"

class CasTest < BaseTest

  def test_simple_cas
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key key
    new_flags = flags * 2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, cas_key, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the stored item with cas update
    send_get_cmd key, true
    expected_msg = expected_get_response key, new_flags, new_value.length, new_value, cas_key + 1
    assert_equal expected_msg, read_reply(3)
  end

  def test_exists_cas
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key key
    new_cas_key = cas_key + 1
    new_flags = flags + 3
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, new_cas_key, new_value, false
    assert_equal Memcached::EXISTS_MSG, read_reply

    # Get the initial item without updates
    send_get_cmd key, true
    expected_msg = expected_get_response key, flags, value.length, value, cas_key
    assert_equal expected_msg, read_reply(3)
  end

  def test_not_found_cas
    cas_key = 5
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::NOT_FOUND_MSG, read_reply

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_no_reply_cas
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key key
    new_flags = flags + 2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, cas_key, new_value, true

    # Get the stored item with cas update
    send_get_cmd key, true
    expected_msg = expected_get_response key, new_flags, new_value.length, new_value, cas_key + 1
    assert_equal expected_msg, read_reply(3)
  end

  # ####     Test invalid parameters

  def test_negative_cas_unique_key
    cas_key = -2
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end

  # cas_unique_key bigger than the maximum 64-bit integer
  def test_exceeds_max_cas_unique_key
    cas_key = Memcached::CAS_KEY_LIMIT + 1
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_string_cas_unique_key
    cas_key = 'unique_cas_key'
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_empty_string_cas_unique_key
    cas_key = nil
    send_storage_cmd Memcached::CAS_CMD_NAME, key, flags, exptime, value.length, cas_key, value, false
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    send_get_cmd key, true
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_exptime_cas
    # Set item that never expires
    exptime = 0
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, false, value, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Cas with exptime = 3 seconds
    cas_key = get_cas_key key
    new_flags = flags + 4
    exptime = 3
    send_storage_cmd Memcached::CAS_CMD_NAME, key, new_flags, exptime, new_value.length, cas_key, new_value, false
    assert_equal Memcached::STORED_MSG, read_reply

    send_get_cmd key
    expected_msg = expected_get_response key, new_flags, new_value.length, new_value
    assert_equal expected_msg, read_reply(3)

    wait_for_purge_exec
    
    # Get expired item
    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  ##### Test cas error responses

  def test_noreply_syntax_error_cas
    no_reply = "#{Memcached::NO_REPLY}#{Memcached::NO_REPLY}"
    socket.puts "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{cas_key} #{no_reply}#{Memcached::CMD_ENDING}"
    socket.puts "#{value}#{Memcached::CMD_ENDING}"

    assert_equal "#{Memcached::CLIENT_ERROR}\"#{Memcached::NO_REPLY}\" was expected as the 7th argument, but \"#{no_reply}\" was received#{Memcached::CMD_ENDING}", read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end

  def test_invalid_cmd_termination
    socket.puts "#{Memcached::CAS_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} #{cas_key} #{Memcached::NO_REPLY}\n#{Memcached::CMD_ENDING}"
    assert_equal Memcached::CMD_TERMINATION_MSG, read_reply

    send_get_cmd key
    assert_equal Memcached::END_MSG, read_reply
  end
end