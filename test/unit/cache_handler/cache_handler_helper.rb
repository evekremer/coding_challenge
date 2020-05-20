# frozen_string_literal: true

require_relative '../../test_helper'

class CacheHandlerHelper < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
  end

  def assert_get_storage(cmd_name, params, data_block)
    storage_obj = Memcached::StorageCommand.new cmd_name, params, data_block
    expected_get = data_to_hash storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, @cache_handler.cas_key, storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj.key)
  end
end
