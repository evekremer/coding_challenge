# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test pre_append method for CacheHandler class
class PreAppendHandlerTest < BaseTest
  def setup
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block
    @cache_handler.storage_handler @set_storage_obj

    data_block = 'pre_append'
    parameters = [key.to_s, (flags + 2).to_s, (exptime + 200).to_s, data_block.length.to_s]
    @prepend_storage_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    @append_storage_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
  end

  # Prepend

  def test_simple_prepend
    reply = @cache_handler.storage_handler @prepend_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    new_data_block = @prepend_storage_obj.data_block + @set_storage_obj.data_block
    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, new_data_block.length.to_s, @cache_handler.cas_key, new_data_block
    assert_equal expected_get, @cache_handler.cache.get(@prepend_storage_obj.key)
  end

  def test_missing_key_prepend
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    prepend_storage_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler prepend_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    assert_nil @cache_handler.cache.get(prepend_storage_obj.key)
  end

  def test_empty_prepend
    data_block = ''
    parameters = [@set_storage_obj.key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block

    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end

  def test_data_block_too_long_prepend
    # Prepending the existing value exceeds max length
    data_block = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - @set_storage_obj.length.to_i + 1)
    parameters = [@set_storage_obj.key.to_s, (flags + 5).to_s, (exptime + 200).to_s, data_block.length.to_s]
    prepend_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block

    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.storage_handler prepend_obj
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end

  # Append

  def test_simple_append
    reply = @cache_handler.storage_handler @append_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    new_data_block = @set_storage_obj.data_block + @append_storage_obj.data_block
    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, new_data_block.length.to_s, @cache_handler.cas_key, new_data_block
    assert_equal expected_get, @cache_handler.cache.get(@append_storage_obj.key)
  end

  def test_missing_key_append
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    append_storage_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler append_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    assert_nil @cache_handler.cache.get(append_storage_obj.key)
  end

  def test_empty_append
    data_block = ''
    parameters = [@set_storage_obj.key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block

    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end

  def test_data_block_too_long_append
    # Appending the existing value exceeds max length
    data_block = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - @set_storage_obj.length.to_i + 1)
    parameters = [@set_storage_obj.key.to_s, (flags + 5).to_s, (exptime + 200).to_s, data_block.length.to_s]
    prepend_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block

    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.storage_handler prepend_obj
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end
end
