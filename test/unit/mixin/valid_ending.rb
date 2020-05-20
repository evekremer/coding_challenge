# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
# Test validate_and_remove_ending! method
class MixinValidateEndingTest < BaseTest
  include Memcached::Mixin

  def test_validate_ending_length_zero
    command = '' # length zero

    exception = assert_raise Memcached::ArgumentClientError do
      validate_and_remove_ending! command
    end
    assert_equal Memcached::CMD_TERMINATION_MSG, exception.message
  end

  def test_validate_ending_length_one
    command = 'c' # length one

    exception = assert_raise Memcached::ArgumentClientError do
      validate_and_remove_ending! command
    end
    assert_equal Memcached::CMD_TERMINATION_MSG, exception.message
  end

  def test_validate_ending_valid_ending
    command = Memcached::CMD_ENDING

    parsed_command = validate_and_remove_ending! command
    assert_equal command[0..-3], parsed_command
  end

  def test_validate_ending_with_valid_ending
    command = "#{key}#{Memcached::CMD_ENDING}"

    parsed_command = validate_and_remove_ending! command
    assert_equal command[0..-3], parsed_command
  end

  def test_validate_ending_invalid_ending
    command = '##'

    exception = assert_raise Memcached::ArgumentClientError do
      validate_and_remove_ending! command
    end
    assert_equal Memcached::CMD_TERMINATION_MSG, exception.message
  end

  def test_validate_ending_with_invalid_ending
    command = 'command##'

    exception = assert_raise Memcached::ArgumentClientError do
      validate_and_remove_ending! command
    end
    assert_equal Memcached::CMD_TERMINATION_MSG, exception.message
  end

  def test_validate_ending_typerror_int
    command = 12

    assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end

  def test_validate_ending_typerror_nil
    command = nil

    assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end

  def test_validate_ending_typerror_array
    command = ["#{key}#{Memcached::CMD_ENDING}"]

    assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end
end
