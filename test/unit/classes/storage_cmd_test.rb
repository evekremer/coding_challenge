
require_relative "../../test_helper"

# Unit test for Memcached::StorageCommand class
class StorageCommandTest < BaseTest

  #################### Test command_name attribute

  def test_valid_set_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal Memcached::SET_CMD_NAME, storage_obj.command_name
  end

  def test_valid_add_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::ADD_CMD_NAME, parameters, data_block)

    assert_equal Memcached::ADD_CMD_NAME, storage_obj.command_name
  end

  def test_valid_replace_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::REPLACE_CMD_NAME, parameters, data_block)

    assert_equal Memcached::REPLACE_CMD_NAME, storage_obj.command_name
  end

  def test_valid_prepend_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::PREPEND_CMD_NAME, parameters, data_block)

    assert_equal Memcached::PREPEND_CMD_NAME, storage_obj.command_name
  end

  def test_valid_append_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::APPEND_CMD_NAME, parameters, data_block)

    assert_equal Memcached::APPEND_CMD_NAME, storage_obj.command_name
  end

  def test_invalid_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    assert_raise ArgumentError do
      storage_obj = Memcached::StorageCommand.new(data_block, parameters, data_block)
    end
  end

  def test_coerces_string_type_command_name
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    assert_raise ArgumentError do
      storage_obj = Memcached::StorageCommand.new(data_block.length, parameters, data_block)
    end
  end

  #################### Test key attribute
  
  def test_valid_key
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal parameters[0], storage_obj.key
  end

  def test_key_not_provided
    data_block = value
    parameters = ['', "#{flags}", "#{exptime}", "#{data_block.length}"]
    
    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  def test_key_with_control_chars
    data_block = value
    key = "key_\t_\0_\n_"
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, exception.message
  end

  def test_key_too_long
    data_block = value
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::KEY_TOO_LONG_MSG, exception.message
  end

  def test_nil_key
    data_block = value
    parameters = [nil, "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  def test_coerces_string_type_key
    data_block = value
    key_ = key.to_i # Numeric key
    parameters = [key_, "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal key_.to_s, storage_obj.key
  end

  #################### Test flags attribute

  def test_valid_flags
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal parameters[1], storage_obj.flags
  end

  def test_invalid_string_flags
    data_block = value
    flags = 'invalid_flags'
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_invalid_nil_flags
    data_block = value
    flags = nil
    parameters = ["#{key}", flags, "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::FLAGS_TYPE_MSG, exception.message
  end

  def test_coerces_string_type_flags
    data_block = value
    flags = 1 # Numeric flags
    parameters = ["#{key}", flags, "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal flags.to_s, storage_obj.flags
  end

  #################### Test exptime attribute

  def test_valid_exptime
    data_block = value
    exptime = 40
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal Time.now.round + exptime, storage_obj.expdate.round # Offset from current time
  end

  def test_valid_exptime_zero
    data_block = value
    exptime = 0
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal 0, storage_obj.expdate # Never expires
  end

  def test_valid_exptime_negative
    data_block = value
    exptime = -4
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal Time.now.round, storage_obj.expdate.round # Immediately expired
  end

  def test_valid_exptime_unix_time
    data_block = value
    exptime = 30 * (Memcached::SECONDS_PER_DAY + 1)
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal Memcached::UNIX_TIME + exptime, storage_obj.expdate # Offset from 1/1/1970 (Unix time)
  end

  def test_invalid_string_exptime
    data_block = value
    exptime = 'invalid_exptime'
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end

  def test_invalid_nil_exptime
    data_block = value
    exptime = nil
    parameters = ["#{key}", "#{flags}", exptime, "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end

  def test_invalid_date_type_exptime
    data_block = value
    exptime = Time.now
    parameters = ["#{key}", "#{flags}", exptime, "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::EXPTIME_TYPE_MSG, exception.message
  end

  #################### Test length attribute

  def test_valid_length
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal parameters[3], storage_obj.length
  end

  def test_invalid_length
    data_block = value
    length = 'invalid_length'
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end
    
    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end

  def test_invalid_nil_length
    data_block = value
    length = nil
    parameters = ["#{key}", "#{flags}", "#{exptime}", length]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::LENGTH_TYPE_MSG, exception.message
  end

  def test_coerces_string_type_length
    data_block = value
    length = data_block.length # Numeric length
    parameters = ["#{key}", "#{flags}", "#{exptime}", length]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal length.to_s, storage_obj.length
  end

  #################### Test data_block attribute

  def test_valid_datablock
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal data_block, storage_obj.data_block
  end

  def test_invalid_datablock_length
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length + 2}"]

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::CLIENT_ERROR + "<length> (#{data_block.length + 2}) is not equal to the length of the item's data_block (#{data_block.length})" + Memcached::CMD_ENDING, exception.message
  end

  def test_invalid_datablock_max_length
    data_block = 'd' * (Memcached::MAX_DATA_BLOCK_LENGTH + 1)
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message
  end

  def test_nil_datablock
    data_block = nil
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.to_s.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal data_block.to_s, storage_obj.data_block
  end

  def test_coerces_string_type_datablock
    data_block = 123
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.to_s.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal data_block.to_s, storage_obj.data_block
  end

  #################### Test parameters_max_length attribute
  
  def test_default_parameters_max_length
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal Memcached::StorageCommand::PARAMETERS_MAX_LENGTH, storage_obj.parameters_max_length
  end

  def test_coerces_integer_type_parameters_max_length
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block, '5')

    assert_equal 5, storage_obj.parameters_max_length
  end
  
  def test_less_parameters_than_min_length
    parameters = []

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, value)
    end

    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_array_type_parameters
    parameters = 1

    assert_raise TypeError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, value)
    end
  end

  def test_more_parameters_than_max_length
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{Memcached::NO_REPLY}", 'extra_parameter']

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, exception.message
  end

  #################### Test no reply

  def test_with_valid_no_reply
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{Memcached::NO_REPLY}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert storage_obj.no_reply
  end

  def test_with_syntax_error_no_reply
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", 'no__replyy']

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)
    end

    assert_equal Memcached::CLIENT_ERROR + "\"#{Memcached::NO_REPLY}\" was expected as the #{Memcached::StorageCommand::PARAMETERS_MAX_LENGTH+1}th argument, but \"#{parameters[Memcached::StorageCommand::PARAMETERS_MAX_LENGTH-1]}\" was received" + Memcached::CMD_ENDING, exception.message
  end

  def test_without_no_reply
    data_block = value
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj = Memcached::StorageCommand.new(Memcached::SET_CMD_NAME, parameters, data_block)

    assert_equal false, storage_obj.no_reply
  end
end