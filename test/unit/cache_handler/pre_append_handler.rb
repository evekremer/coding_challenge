# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test pre_append method for CacheHandler class
class PreAppendHandlerTest < CacheHandlerHelper
  # Prepend

  def test_simple_prepend
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters = [key.to_s, flags.to_s, 100, new_value.length.to_s]
    assert_new_storage Memcached::PREPEND_CMD_NAME, parameters, new_value

    parameters = [key.to_s, flags.to_s, 100, (new_value + data_block).length.to_s]
    assert_get_storage parameters, (new_value + data_block)
  end

  def test_missing_key_prepend
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::PREPEND_CMD_NAME, parameters, data_block, Memcached::NOT_STORED_MSG
    assert_nil @cache_handler.cache.get(key)
  end

  def test_empty_prepend
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters = [key.to_s, flags.to_s, 100, ''.length.to_s]
    assert_new_storage Memcached::PREPEND_CMD_NAME, parameters, ''

    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_get_storage parameters, data_block
  end

  def test_data_block_too_long_prepend
    # Prepending the existing value exceeds max length
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    data_block_prepend = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - parameters[3].to_i + 1)
    parameters_prepend = [key.to_s, (flags + 5).to_s, 100, data_block_prepend.length.to_s]

    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.new_storage Memcached::PREPEND_CMD_NAME, parameters_prepend, data_block_prepend
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    assert_get_storage parameters, data_block
  end

  # Append

  def test_simple_append
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters = [key.to_s, flags.to_s, 100, new_value.length.to_s]
    assert_new_storage Memcached::APPEND_CMD_NAME, parameters, new_value

    parameters = [key.to_s, flags.to_s, 100, (data_block + new_value).length.to_s]
    assert_get_storage parameters, (data_block + new_value)
  end

  def test_missing_key_append
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::APPEND_CMD_NAME, parameters, data_block, Memcached::NOT_STORED_MSG
    assert_nil @cache_handler.cache.get(key)
  end

  def test_empty_append
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters = [key.to_s, flags.to_s, 100, ''.length.to_s]
    assert_new_storage Memcached::APPEND_CMD_NAME, parameters, ''

    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_get_storage parameters, data_block
  end

  def test_data_block_too_long_append
    # Appending the existing value exceeds max length
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    data_block_append = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - parameters[3].to_i + 1)
    parameters_append = [key.to_s, (flags + 5).to_s, 100, data_block_append.length.to_s]

    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.new_storage Memcached::APPEND_CMD_NAME, parameters_append, data_block_append
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    assert_get_storage parameters, data_block
  end
end
