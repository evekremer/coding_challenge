# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test cas method for CacheHandler class
class CasHandlerTest < CacheHandlerHelper
  def test_stored_cas
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters_ = [key, (flags + 9), 120, new_value.length, @cache_handler.cas_key]
    assert_new_storage Memcached::CAS_CMD_NAME, parameters_, new_value

    assert_get_storage parameters_, new_value, true
  end

  def test_exists_cas
    parameters = [key, flags, 100, data_block.length]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    parameters_ = [key, (flags + 9), exptime, new_value.length, (@cache_handler.cas_key + 9)]
    assert_new_storage Memcached::CAS_CMD_NAME, parameters_, new_value, Memcached::EXISTS_MSG

    assert_get_storage [key, flags, 100, data_block.length, @cache_handler.cas_key], data_block, true
  end

  def test_not_found_cas
    parameters = [key, flags.to_s, exptime.to_s, data_block.length.to_s, @cache_handler.cas_key.to_s]
    assert_new_storage Memcached::CAS_CMD_NAME, parameters, data_block, Memcached::NOT_FOUND_MSG

    assert_nil @cache_handler.cache.get(key)
  end

  def test_empty_data_block_cas
    parameters = [key.to_s, flags.to_s, 100, data_block.length.to_s]
    assert_new_storage Memcached::SET_CMD_NAME, parameters, data_block

    data_block = ''
    parameters = [key, flags.to_s, exptime.to_s, data_block.length.to_s, @cache_handler.cas_key.to_s]
    assert_new_storage Memcached::CAS_CMD_NAME, parameters, data_block

    assert_get_storage parameters, data_block, true
  end
end
