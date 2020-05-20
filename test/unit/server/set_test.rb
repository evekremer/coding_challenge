# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
class ServerSetTest < ServerTestHelper
  include Memcached::Mixin

  def test_set_simple
    assert_send_set key, flags, exptime, value
    assert_multine_get key, flags, value
  end

  def test_set_empty_key
    assert_send_set '', flags, exptime, value, Memcached::KEY_NOT_PROVIDED_MSG
  end

  def test_set_empty_value
    assert_send_set key, flags, exptime, ''
    assert_multine_get key, flags, ''
  end

  #### Test control characters included in data_block
  # Unstructured data is terminated by \r\n, even though \r, \n
  # or any other 8-bit characters may also appear inside the data

  def test_set_value_termination_chars
    value = "\r\nval\r\nwith\r\ntermination\r\nchars\r\n\r\n"
    assert_send_set key, flags, exptime, value
    assert_multine_get key, flags, value, (3 + value.count("\n"))
  end

  def test_set_value_only_termination_chars
    value = Memcached::CMD_ENDING
    assert_send_set key, flags, exptime, value
    assert_multine_get key, flags, value, (3 + value.count("\n"))
  end

  def test_set_value_only_newline_control_char
    value = "value with newline\n"
    assert_send_set key, flags, exptime, value
    assert_multine_get key, flags, value, (3 + value.count("\n"))
  end

  def test_set_value_only_cr_control_char
    value = "value with carrige return\r"
    assert_send_set key, flags, exptime, value
    assert_multine_get key, flags, value
  end

  ####     Test invalid parameters

  #=> Key

  def test_set_key_with_whitespaces_1
    key = 'key with whitespaces'
    assert_send_set key, flags, exptime, value, Memcached::TOO_MANY_ARGUMENTS_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_key_with_whitespaces_2
    key = '   key   '
    assert_send_set key, flags, exptime, value, Memcached::TOO_MANY_ARGUMENTS_MSG
    assert_get key, Memcached::KEY_NOT_PROVIDED_MSG
  end

  def test_set_key_control_chars_tab
    key = "key\twith_tabs"
    assert_send_set key, flags, exptime, value, Memcached::KEY_WITH_CONTROL_CHARS_MSG
    assert_get key, Memcached::KEY_WITH_CONTROL_CHARS_MSG
  end

  def test_set_key_multiple_control_char
    key = "\a\akey\bwith\vmultiple_control\f_chars"
    assert_send_set key, flags, exptime, value, Memcached::KEY_WITH_CONTROL_CHARS_MSG
    assert_get key, Memcached::KEY_WITH_CONTROL_CHARS_MSG
  end

  #=> Flags

  def test_set_negative_flags
    assert_send_set key, -4, exptime, value, Memcached::FLAGS_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_flags_exceeds_max
    # flags bigger than the maximum 16-bit integer
    assert_send_set key, (Memcached::FLAGS_LIMIT + 1), exptime, value, Memcached::FLAGS_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_string_with_digits_flags
    assert_send_set key, 'test_flags_1234', exptime, value, Memcached::FLAGS_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_empty_flags
    assert_send_set key, '', exptime, value, Memcached::FLAGS_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  #=> Exptime

  def test_set_string_exptime_with_digits
    assert_send_set key, flags, 'test_exptime_1234', value, Memcached::EXPTIME_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_empty_exptime
    assert_send_set key, flags, '', value, Memcached::EXPTIME_TYPE_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_exptime_set
    assert_send_set key, flags, 3, value

    assert_multine_get key, flags, value
    wait_for_purge_exec
    assert_get key, Memcached::END_MSG
  end

  def test_set_expired
    assert_send_set key, flags, -1, value
    assert_get key, Memcached::END_MSG
  end

  #=> Length

  def test_set_negative_length
    assert_send_set key, flags, exptime, value, Memcached::LENGTH_TYPE_MSG, -6
    assert_get key, Memcached::END_MSG
  end

  def test_set_string_length_with_digits
    assert_send_set key, flags, exptime, value, Memcached::LENGTH_TYPE_MSG, 'test_length_1234'
    assert_get key, Memcached::END_MSG
  end

  def test_set_empty_length
    assert_send_set key, flags, exptime, value, Memcached::TOO_FEW_ARGUMENTS_MSG, ''
    assert_get key, Memcached::END_MSG
  end

  #=> Test max length for key and data_block

  def test_set_value_too_long
    value = 'v' * (Memcached::MAX_DATA_BLOCK_LENGTH + 1)
    assert_send_set key, flags, exptime, value, Memcached::DATA_BLOCK_TOO_LONG_MSG
    assert_get key, Memcached::END_MSG
  end

  def test_set_key_too_long
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    assert_send_set key, flags, exptime, value, Memcached::KEY_TOO_LONG_MSG
    assert_get key, Memcached::KEY_TOO_LONG_MSG
  end

  #=> no_reply

  def test_set_no_reply
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, value.length, value, true
    assert_multine_get key, flags, value
  end

  def test_set_noreply_syntax_error
    socket.puts "#{Memcached::SET_CMD_NAME} #{key} #{flags} #{exptime} #{value.length} norep#{Memcached::CMD_ENDING}#{value}#{Memcached::CMD_ENDING}"

    excepted_reply = no_reply_syntax_error_msg 'norep', Memcached::STORAGE_CMD_PARAMETERS_MAX_LENGTH
    assert_equal excepted_reply, read_reply

    assert_get key, Memcached::END_MSG
  end
end
