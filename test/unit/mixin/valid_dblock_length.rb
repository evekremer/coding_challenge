# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test validate_data_block_length! and
#    validate_length! methods
class MixinValidateDatablockLengthTest < BaseTest
  include Memcached::Mixin

  ###   Test validate_data_block_length! method

  def test_validate_db_length
    assert_nothing_raised do
      validate_data_block_length! data_block.length, data_block
    end
  end

  def test_validate_db_length_smaller
    length = data_block.length - 4

    exception = assert_raise Memcached::ArgumentClientError do
      validate_data_block_length! length, data_block
    end

    expected_msg = data_block_length_error_msg length, data_block
    assert_equal expected_msg, exception.message
  end

  def test_validate_db_length_bigger
    length = data_block.length + 4

    exception = assert_raise Memcached::ArgumentClientError do
      validate_data_block_length! length, data_block
    end

    expected_msg = data_block_length_error_msg length, data_block
    assert_equal expected_msg, exception.message
  end

  def test_validate_db_length_too_long
    data_block = 'd' * (Memcached::MAX_DATA_BLOCK_LENGTH + 1)

    exception = assert_raise Memcached::TypeClientError do
      validate_data_block_length! data_block.length, data_block
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message
  end

  def test_validate_db_length_nil
    length = nil

    assert_raise TypeError do
      validate_data_block_length! length, data_block
    end
  end

  def test_validate_db_length_nil_db
    data_block = nil

    assert_nothing_raised do
      validate_data_block_length! 0, data_block
    end
  end

  ###   Test validate_length! method

  def test_validate_length_integer_positive
    assert_nothing_raised do
      validate_length! 123
    end
  end

  def test_validate_length_integer_negative
    exception = assert_raise Memcached::TypeClientError do
      validate_length! -123
    end

    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end

  def test_validate_length_integer_zero
    assert_nothing_raised do
      validate_length! 0
    end
  end

  def test_validate_length_string_digits
    assert_nothing_raised do
      validate_length! '123'
    end
  end

  def test_validate_length_float
    exception = assert_raise Memcached::TypeClientError do
      validate_length! 5.0
    end

    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end

  def test_validate_length_string_non_digits
    exception = assert_raise Memcached::TypeClientError do
      validate_length! 'test'
    end

    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end

  def test_validate_length_nil
    exception = assert_raise Memcached::TypeClientError do
      validate_length! nil
    end

    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end
end
