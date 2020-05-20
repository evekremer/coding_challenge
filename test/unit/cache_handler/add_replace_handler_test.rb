# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test add_replace method for CacheHandler class
class AddReplaceHandlerTest < BaseTest
  def setup
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block

    @data_block = 'add_replace'
    @parameters = [key.to_s, (flags + 1).to_s, (exptime + 100).to_s, data_block.length.to_s]
    @add_storage_obj = Memcached::StorageCommand.new Memcached::ADD_CMD_NAME, parameters, data_block
    @replace_storage_obj = Memcached::StorageCommand.new Memcached::REPLACE_CMD_NAME, parameters, data_block
  end

  # Add

  def test_simple_add
    reply = @cache_handler.storage_handler Memcached::ADD_CMD_NAME, @parameters, @data_block
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash key, flags, expdate, length, @cache_handler.cas_key, @data_block
    assert_equal expected_get, @cache_handler.cache.get(key)
  end

  def test_invalid_add
    @cache_handler.storage_handler @set_storage_obj

    reply = @cache_handler.storage_handler @add_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end

  def test_empty_add
    data_block = ''
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::ADD_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash storage_obj_empty.key, storage_obj_empty.flags, storage_obj_empty.expdate, storage_obj_empty.length, @cache_handler.cas_key, storage_obj_empty.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end

  # Replace

  def test_simple_replace
    @cache_handler.storage_handler @set_storage_obj

    reply = @cache_handler.storage_handler @replace_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @replace_storage_obj.key, @replace_storage_obj.flags, @replace_storage_obj.expdate, @replace_storage_obj.length, @cache_handler.cas_key, @replace_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@replace_storage_obj.key)
  end

  def test_invalid_replace
    reply = @cache_handler.storage_handler @replace_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    assert_nil @cache_handler.cache.get(@replace_storage_obj.key)
  end

  def test_empty_replace
    @cache_handler.storage_handler @set_storage_obj

    data_block = ''
    parameters = [@set_storage_obj.key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::REPLACE_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, storage_obj_empty.expdate, storage_obj_empty.length, @cache_handler.cas_key, storage_obj_empty.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end
end
