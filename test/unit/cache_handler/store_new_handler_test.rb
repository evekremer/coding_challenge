# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test add_replace and store_new_item methods for CacheHandler class
class StoreNewHandlerTest < CacheHandlerHelper
  ### Set

  def test_simple_set
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block
    assert_get_storage parameters, data_block
  end

  def test_empty_datablock_set
    data_block = ''
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block
    assert_get_storage parameters, data_block
  end

  ### Add

  def test_simple_add
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::ADD_CMD_NAME, parameters, data_block
    assert_get_storage parameters, data_block
  end

  def test_invalid_add
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block
    assert_new_storage Memcached::ADD_CMD_NAME, parameters, data_block, Memcached::NOT_STORED_MSG
    assert_get_storage parameters, data_block
  end

  def test_empty_add
    data_block = ''
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::ADD_CMD_NAME, parameters, data_block
    assert_get_storage parameters, data_block
  end

  ### Replace

  def test_simple_replace
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters = [key.to_s, (flags + 3).to_s, (exptime + 10).to_s, new_value.length.to_s]
    assert_new_storage Memcached::REPLACE_CMD_NAME, parameters, new_value
    assert_get_storage parameters, new_value
  end

  def test_invalid_replace
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::REPLACE_CMD_NAME, parameters, data_block, Memcached::NOT_STORED_MSG
    assert_nil @cache_handler.cache.get(key)
  end

  def test_empty_replace
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    data_block = ''
    parameters = [key.to_s, (flags + 3).to_s, (exptime + 100).to_s, data_block.length.to_s]
    assert_new_storage Memcached::REPLACE_CMD_NAME, parameters, data_block

    assert_get_storage parameters, data_block
  end
end
