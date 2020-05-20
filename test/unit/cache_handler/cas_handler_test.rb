# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test cas method for CacheHandler class
class CasHandlerTest < BaseTest
  def setup
    exptime_ = exptime
    parameters = [key.to_s, flags.to_s, exptime_.to_s, data_block.length.to_s]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block
    @cache_handler.storage_handler @set_storage_obj

    # Different parameters except for 'key' as @set_storage_obj
    data_block = 'cas_data_block_1'
    parameters = [key.to_s, (flags + 1).to_s, (exptime_ + 100).to_s, data_block.length.to_s, @cache_handler.cas_key.to_s]
    @cas_obj_stored = Memcached::CasCommand.new parameters, data_block

    # Different cas_key (only) from @cas_obj_stored
    parameters = [key.to_s, (flags + 1).to_s, (exptime_ + 100).to_s, data_block.length.to_s, (@cache_handler.cas_key + 7).to_s]
    @cas_obj_exists = Memcached::CasCommand.new parameters, data_block

    # Different parameteres from @set_storage_obj
    data_block = 'cas_data_block_2'
    parameters = ["#{key}_", (flags + 4).to_s, (exptime_ + 200).to_s, data_block.length.to_s, @cache_handler.cas_key.to_s]
    @cas_obj_not_found = Memcached::CasCommand.new parameters, data_block

    # Same parameters as cas_obj_stored, but with empty data_block
    data_block = ''
    parameters = [key.to_s, (flags + 1).to_s, (exptime_ + 100).to_s, data_block.length.to_s, @cache_handler.cas_key.to_s]
    @cas_obj_empty = Memcached::CasCommand.new parameters, data_block
  end

  def test_stored_cas
    reply = @cache_handler.storage_handler @cas_obj_stored
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @cas_obj_stored.key, @cas_obj_stored.flags, @cas_obj_stored.expdate, @cas_obj_stored.length, @cache_handler.cas_key, @cas_obj_stored.data_block
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_stored.key)
  end

  def test_exists_cas
    reply = @cache_handler.storage_handler @cas_obj_exists
    assert_equal Memcached::EXISTS_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_exists.key)
  end

  def test_not_found_cas
    reply = @cache_handler.storage_handler @cas_obj_not_found
    assert_equal Memcached::NOT_FOUND_MSG, reply

    assert_nil @cache_handler.cache.get(@cas_obj_not_found.key)
  end

  def test_empty_data_block_cas
    reply = @cache_handler.storage_handler @cas_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @cas_obj_empty.key, @cas_obj_empty.flags, @cas_obj_empty.expdate, @cas_obj_empty.length, @cache_handler.cas_key, @cas_obj_empty.data_block
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_empty.key)
  end
end
