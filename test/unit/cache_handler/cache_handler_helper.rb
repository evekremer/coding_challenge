# frozen_string_literal: true

require_relative '../../test_helper'

class CacheHandlerHelper < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
  end

  def assert_get_storage(params, data_block, cas = false)
    if cas
      storage_obj = Memcached::CasCommand.new params, data_block
    else
      storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, params, data_block
    end
    expected_get = data_to_hash storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, @cache_handler.cas_key, storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj.key)
  end

  def assert_new_storage(cmd_name, parameters, data_block, msg = Memcached::STORED_MSG)
    reply = @cache_handler.new_storage cmd_name, parameters, data_block
    assert_equal msg, reply
  end
end
