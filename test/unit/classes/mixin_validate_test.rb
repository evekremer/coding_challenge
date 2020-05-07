
require_relative "../../test_helper"

# Unit test for Memcached::Mixin module for validate_*! methods
class MixinValidateTest < BaseTest
  include Memcached::Mixin
  
  ####### Test validate_and_remove_ending! method
  
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

    exception = assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end

  def test_validate_ending_typerror_nil
    command = nil

    exception = assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end

  def test_validate_ending_typerror_array
    command = ["#{key}#{Memcached::CMD_ENDING}"]

    exception = assert_raise TypeError do
      validate_and_remove_ending! command
    end
  end

  ####### Test validate_data_block_length! method

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

  ####### Test validate_parameters_min_length! method

  def test_validate_parameters_min_length_equal
    parameters = ["#{key}"]
    min_length = parameters.length
    
    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_parameters_min_length_smaller
    parameters = ["#{key}"]
    min_length = parameters.length - 1
    
    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_parameters_min_length_bigger
    parameters = ["#{key}"]
    min_length = parameters.length + 1
    
    exception = assert_raise Memcached::ArgumentClientError do
      validate_parameters_min_length! parameters, min_length
    end
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_validate_parameters_min_length_empty
    parameters = []
    min_length = parameters.length

    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_min_length_coerces_array_type
    parameters = 1
    min_length = 1

    assert_nothing_raised do
      validate_parameters_max_length! parameters, min_length
    end
  end

  ####### Test validate_parameters_max_length! method

  def test_validate_parameters_max_length_equal
    parameters = ["#{key}"]
    max_length = parameters.length
    
    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_parameters_max_length_bigger
    parameters = ["#{key}"]
    max_length = parameters.length + 1
    
    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_parameters_max_length_smaller
    parameters = ["#{key}"]
    max_length = parameters.length - 1
    
    exception = assert_raise Memcached::ArgumentClientError do
      validate_parameters_max_length! parameters, max_length
    end
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, exception.message
  end

  def test_validate_parameters_max_length_empty
    parameters = []
    max_length = parameters.length

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_max_length_coerces_array_type
    parameters = 1
    max_length = 1

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  ####### Test validate_flags! method

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
  
  ####### Test validate_length! method

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
  
  ####### Test validate_exptime! method

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

  ####### Test validate_key! method

  # Validate key is not empty

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

  # Contains control characters

  def test_validate_key_with_control_chars
    exception = assert_raise Memcached::TypeClientError do
      validate_key! "#{key}\r\n"
    end

    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, exception.message
  end

  # Validate key length

  def test_validate_key_valid_length
    key = 'k' * (Memcached::MAX_KEY_LENGTH)
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
    key = 10 ** (Memcached::MAX_KEY_LENGTH)
    exception = assert_raise Memcached::TypeClientError do
      validate_key! key
    end

    assert_equal Memcached::KEY_TOO_LONG_MSG, exception.message
  end
end