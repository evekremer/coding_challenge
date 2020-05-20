# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::CasCommand class
class Memcached::CasCommandTest < BaseTest
  include Memcached::Mixin
  # Test command_name attribute

  def test_valid_cas_command_name
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s]
    storage_obj = Memcached::CasCommand.new parameters, data_block

    assert_equal Memcached::CAS_CMD_NAME, storage_obj.command_name
  end

  # Test cas_key attribute

  def test_valid_cas_key
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s]
    storage_obj = Memcached::CasCommand.new parameters, data_block

    assert_equal parameters[4], storage_obj.cas_key
  end

  def test_valid_negative_cas_key
    negative_cas_key = cas_key * -1
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, negative_cas_key.to_s]

    exception = assert_raise Memcached::TypeClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  def test_valid_cas_key_too_big
    cas_key_too_big = cas_key * Memcached::CAS_KEY_LIMIT
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key_too_big.to_s]

    exception = assert_raise Memcached::TypeClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  def test_coerces_string_type_cas_key
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key]
    storage_obj = Memcached::CasCommand.new parameters, data_block

    assert_equal parameters[4].to_s, storage_obj.cas_key
  end

  def test_nil_cas_key
    cas_key = nil
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key]

    exception = assert_raise Memcached::TypeClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    assert_equal Memcached::CAS_KEY_TYPE_MSG, exception.message
  end

  # Empty data block

  def test_cas_empty_data_block
    data_block = ''
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s]

    assert_nothing_raised do
      Memcached::CasCommand.new parameters, data_block
    end
  end

  # Test invalid number of parameters

  def test_default_parameters_max_length
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s]

    storage_obj = Memcached::CasCommand.new parameters, data_block
    assert_equal Memcached::CAS_CMD_PARAMETERS_MAX_LENGTH, storage_obj.parameters_max_length
  end

  def test_less_parameters_than_min_length
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s] # cas key parameter missing

    exception = assert_raise Memcached::ArgumentClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_more_parameters_than_max_length
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s, Memcached::NO_REPLY.to_s, 'extra_parameter']

    exception = assert_raise Memcached::ArgumentClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, exception.message
  end

  # Test no reply

  def test_with_valid_no_reply
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s, Memcached::NO_REPLY.to_s]

    storage_obj = Memcached::CasCommand.new parameters, data_block
    assert storage_obj.no_reply
  end

  def test_with_syntax_error_no_reply
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s, 'no__replyy']

    exception = assert_raise Memcached::ArgumentClientError do
      Memcached::CasCommand.new parameters, data_block
    end
    excepted_message = no_reply_syntax_error_msg 'no__replyy', Memcached::CAS_CMD_PARAMETERS_MAX_LENGTH
    assert_equal excepted_message, exception.message
  end

  def test_without_no_reply
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s, cas_key.to_s]
    storage_obj = Memcached::CasCommand.new parameters, data_block

    refute storage_obj.no_reply
  end
end
