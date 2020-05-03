#"cas" is a check and set operation which means "store this data but only if no one else has updated since I last fetched it."
require_relative "../test_helper"

class CasTest < BaseTest

  def test_simple_cas
    send_storage_cmd(Memcached::SET_CMD_NAME, key, 3, 300, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key(key)
    val2 = "new_value"

    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 4, 400, val2.length(), cas_key, val2, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get the stored item with cas update
    reply = send_get_cmd(key, true)
    assert_equal expected_get_response(key, 4, val2.length(), val2, cas_key + 1), reply
  end

  def test_exists_cas
    send_storage_cmd(Memcached::SET_CMD_NAME, key, 2, 2000, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key(key)
    val2 = "new_value"

    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 4, 400, val2.length(), cas_key + 1, val2, false)
    assert_equal Memcached::EXISTS_MSG, read_reply

    # Get the initial item without updates
    reply = send_get_cmd(key, true)
    assert_equal expected_get_response(key, 2, value.length(), value, cas_key), reply
  end

  def test_not_found_cas
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 4, 400, value.length(), 5, value, false)
    assert_equal Memcached::NOT_FOUND_MSG, read_reply

    reply = send_get_cmd(key, true)
    assert_equal Memcached::END_MSG, reply
  end

  def test_no_reply_cas
    send_storage_cmd(Memcached::SET_CMD_NAME, key, 3, 300, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    cas_key = get_cas_key(key)
    val2 = "new_value"

    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 4, 400, val2.length(), cas_key, val2, true)

    # Get the stored item with cas update
    reply = send_get_cmd(key, true)
    assert_equal expected_get_response(key, 4, val2.length(), val2, cas_key + 1), reply
  end

  # ####     Test invalid parameters

  def test_negative_cas_unique_key
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 3, 300, value.length(), -2, value, false)
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    reply = send_get_cmd(key, true)
    assert_equal Memcached::END_MSG, reply
  end

  # cas_unique_key bigger than the maximum 64-bit integer
  def test_exceeds_max_cas_unique_key
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 3, 300, value.length(), Memcached::MAX_CAS_KEY+1, value, false)
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    reply = send_get_cmd(key, true)
    assert_equal Memcached::END_MSG, reply
  end

  def test_string_cas_unique_key
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 3, 300, value.length(), "unique_cas_key", value, false)
    assert_equal Memcached::CAS_KEY_TYPE_MSG, read_reply

    reply = send_get_cmd(key, true)
    assert_equal Memcached::END_MSG, reply
  end

  def test_empty_string_cas_unique_key
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 3, 300, value.length(), nil, value, false)
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, read_reply

    reply = send_get_cmd(key, true)
    assert_equal Memcached::END_MSG, reply
  end

  def test_exptime_cas
    # Set item that never expires (exptime = 0)
    send_storage_cmd(Memcached::SET_CMD_NAME, key, 2, 0, value.length(), false, value, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Cas with exptime = 3 seconds
    cas_key = get_cas_key(key)
    val2 = "new_value"
    send_storage_cmd(Memcached::CAS_CMD_NAME, key, 8, 3, val2.length(), cas_key, val2, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Get stored item
    reply = send_get_cmd(key)
    assert_equal expected_get_response(key, 8, val2.length(), val2), reply

    wait_for_purge_exec
    
    # Get expired item
    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  ##### Test cas error responses

  def test_case_sensitive_cas_upcase
    socket.puts "#{Memcached::CAS_CMD_NAME.upcase} #{key} #{flags} #{exptime} #{value.length} #{cas_key}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_case_sensitive_cas_titlecase
    socket.puts "#{Memcached::CAS_CMD_NAME.titlecase} #{key} #{flags} #{exptime} #{value.length} #{cas_key}#{Memcached::CMD_ENDING}"
    assert_equal Memcached::INVALID_COMMAND_NAME_MSG, read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_noreply_syntax_error_cas_1
    socket.puts "cas #{key} 5 300 5 10 noreplynoreply\r\n"
    socket.puts "value\r\n"
    assert_equal "CLIENT_ERROR \"#{Memcached::NOREPLY}\" was expected as the 7th argument, but \"noreplynoreply\" was received\r\n", read_reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end

  def test_noreply_syntax_error_cas_2
    socket.puts "cas #{key} 5 300 5 10 noreply\n\r\n"
    reply = read_reply(2)
    assert_equal Memcached::CMD_TERMINATION_MSG, reply

    reply = send_get_cmd(key)
    assert_equal Memcached::END_MSG, reply
  end
end