# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test validate_key!,
#   validate_flags!
#   and validate_exptime! methods
class MixinValidateAttributesTest < BaseTest
  include Memcached::Mixin

  ###   Test validate_key! method

  #=> Validate key is not empty

  def test_validate_key_not_empty
    assert_nothing_raised do
      validate_key! key
    end
  end

  def test_validate_key_coerces_string_type_int
    assert_nothing_raised do
      validate_key! 123
    end
  end

  def test_validate_key_empty_key
    exception = assert_raise Memcached::TypeClientError do
      validate_key! ''
    end

    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  def test_validate_key_coerces_string_type_nil
    exception = assert_raise Memcached::TypeClientError do
      validate_key! nil
    end

    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  #=> Contains control characters

  def test_validate_key_with_control_chars
    exception = assert_raise Memcached::TypeClientError do
      validate_key! "#{key}\r\n"
    end

    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, exception.message
  end

  #=> Validate key length

  def test_validate_key_valid_length
    key = 'k' * Memcached::MAX_KEY_LENGTH
    assert_nothing_raised do
      validate_key! key
    end
  end

  def test_validate_key_invalid_length
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    exception = assert_raise Memcached::TypeClientError do
      validate_key! key
    end

    assert_equal Memcached::KEY_TOO_LONG_MSG, exception.message
  end

  def test_validate_key_coerces_string_type_key_length
    key = 10**Memcached::MAX_KEY_LENGTH
    exception = assert_raise Memcached::TypeClientError do
      validate_key! key
    end

    assert_equal Memcached::KEY_TOO_LONG_MSG, exception.message
  end

  ###   Test validate_flags! method

  def test_validate_flags_integer_positive
    assert_nothing_raised do
      validate_flags! 123
    end
  end

  def test_validate_flags_integer_negative
    exception = assert_raise Memcached::TypeClientError do
      validate_flags! -123
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_validate_flags_integer_zero
    assert_nothing_raised do
      validate_flags! 0
    end
  end

  def test_validate_flags_out_of_range
    exception = assert_raise Memcached::TypeClientError do
      validate_flags! Memcached::FLAGS_LIMIT + 1
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_validate_flags_float
    exception = assert_raise Memcached::TypeClientError do
      validate_flags! 5.0
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_validate_flags_string_digits_only
    assert_nothing_raised do
      validate_flags! '123'
    end
  end

  def test_validate_flags_string_with_digits
    exception = assert_raise Memcached::TypeClientError do
      validate_flags! 'test123'
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_validate_flags_nil
    exception = assert_raise Memcached::TypeClientError do
      validate_flags! nil
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  ###   Test validate_exptime! method

  def test_validate_exptime_integer_positive
    assert_nothing_raised do
      validate_exptime! 123
    end
  end

  def test_validate_exptime_integer_negative
    assert_nothing_raised do
      validate_exptime! -123
    end
  end

  def test_validate_exptime_integer_zero
    assert_nothing_raised do
      validate_exptime! 0
    end
  end

  def test_validate_exptime_string_digits
    assert_nothing_raised do
      validate_exptime! '123'
    end
  end

  def test_validate_exptime_float
    exception = assert_raise Memcached::TypeClientError do
      validate_exptime! 5.0
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end

  def test_validate_exptime_string_non_digits
    exception = assert_raise Memcached::TypeClientError do
      validate_exptime! 'test'
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end

  def test_validate_exptime_nil
    exception = assert_raise Memcached::TypeClientError do
      validate_exptime! nil
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end
end
