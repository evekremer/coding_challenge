
require_relative "../../test_helper"

# Unit test for Memcached::CasCommand class
class Memcached::CasCommandTest < BaseTest

  #################### Test command_name attribute

  def test_valid_cas_command_name
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}"]
    storage_obj = Memcached::CasCommand.new(parameters, data_block)

    assert_equal Memcached::CAS_CMD_NAME, storage_obj.command_name
  end

  #################### Test cas_key attribute

  def test_valid_cas_key
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}"]
    storage_obj = Memcached::CasCommand.new(parameters, data_block)

    assert_equal parameters[4], storage_obj.cas_key
  end

  def test_valid_negative_cas_key
    negative_cas_key = cas_key * -1
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{negative_cas_key}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  def test_valid_cas_key_too_big
    cas_key_too_big = cas_key * (Memcached::CAS_KEY_LIMIT)
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key_too_big}"]

    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  def test_coerces_string_type_cas_key
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", cas_key]
    storage_obj = Memcached::CasCommand.new(parameters, data_block)

    assert_equal parameters[4].to_s, storage_obj.cas_key
  end

  def test_nil_cas_key
    cas_key = nil
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", cas_key]
    
    exception = assert_raise Memcached::TypeClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  #################### Test invalid number of parameters
  
  def test_default_parameters_max_length
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}"]
    
    storage_obj = Memcached::CasCommand.new(parameters, data_block)
    assert_equal Memcached::CasCommand::CAS_PARAMETERS_MAX_LENGTH, storage_obj.parameters_max_length
  end
  
  def test_less_parameters_than_min_length
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"] # cas key parameter missing
    
    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_more_parameters_than_max_length
    extra = 'extra_parameter'
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}", "#{Memcached::NO_REPLY}", "#{extra}"]

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, exception.message
  end

  #################### Test no reply

  def test_with_valid_no_reply
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}", "#{Memcached::NO_REPLY}"]

    storage_obj = Memcached::CasCommand.new(parameters, data_block)
    assert storage_obj.no_reply
  end

  def test_with_syntax_error_no_reply
    no_reply = 'no__replyy'
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}", "#{no_reply}"]

    exception = assert_raise Memcached::ArgumentClientError do
      storage_obj = Memcached::CasCommand.new(parameters, data_block)
    end
    assert_equal Memcached::CLIENT_ERROR + "\"#{Memcached::NO_REPLY}\" was expected as the #{Memcached::CasCommand::CAS_PARAMETERS_MAX_LENGTH+1}th argument, but \"#{parameters[Memcached::CasCommand::CAS_PARAMETERS_MAX_LENGTH-1]}\" was received" + Memcached::CMD_ENDING, exception.message
  end

  def test_without_no_reply
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}", "#{cas_key}"]
    storage_obj = Memcached::CasCommand.new(parameters, data_block)

    refute storage_obj.no_reply
  end
end