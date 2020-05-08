
require_relative "../../test_helper"

# Unit test for Memcached::StorageCommand class
class StorageCommandTest < BaseTest

  #################### Test command_name attribute

  def test_valid_get_command_name
    keys = ["#{key}"]
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys

    assert_equal Memcached::GET_CMD_NAME, retrieval_obj.command_name
  end

  def test_valid_gets_command_name
    keys = ["#{key}"]
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GETS_CMD_NAME, keys

    assert_equal Memcached::GETS_CMD_NAME, retrieval_obj.command_name
  end

  def test_invalid_command_name
    keys = ["#{key}"]

    assert_raise ArgumentError do
      retrieval_obj = Memcached::RetrievalCommand.new value, keys
    end
  end

  def test_coerces_string_type_command_name
    keys = ["#{key}"]

    assert_raise ArgumentError do
      retrieval_obj = Memcached::RetrievalCommand.new flags, keys
    end
  end

  #################### Test key attribute
  
  def test_valid_key
    keys = ["#{key}"]
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys

    assert_equal keys, retrieval_obj.keys
  end

  def test_key_not_provided
    keys = ['']
    
    exception = assert_raise Memcached::TypeClientError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  def test_key_with_control_chars
    key = "key_\t_\0_\n_"
    keys = ["#{key}"]

    exception = assert_raise Memcached::TypeClientError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
    assert_equal Memcached::KEY_WITH_CONTROL_CHARS_MSG, exception.message
  end

  def test_key_too_long
    key = 'k' * (Memcached::MAX_KEY_LENGTH + 1)
    keys = ["#{key}"]

    exception = assert_raise Memcached::TypeClientError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
    assert_equal Memcached::KEY_TOO_LONG_MSG, exception.message
  end

  def test_nil_key
    keys = [nil]

    exception = assert_raise Memcached::TypeClientError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
    assert_equal Memcached::KEY_NOT_PROVIDED_MSG, exception.message
  end

  def test_coerces_string_type_key
    keys = [6] # Numeric key
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys

    assert_equal keys[0].to_s, retrieval_obj.keys[0]
  end

  #################### Test keys array minimum length attribute
  
  def test_less_keys_than_min_length
    keys = []

    exception = assert_raise Memcached::ArgumentClientError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_array_type_keys
    keys = 1

    assert_raise TypeError do
      retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    end
  end
end