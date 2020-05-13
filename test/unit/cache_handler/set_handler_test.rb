require_relative "../../test_helper"

# Test store_new_item method for CacheHandler class
class SetHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
    
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block

    data_block = ''
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    @storage_obj_empty = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block
  end

  def test_simple_set
    reply = @cache_handler.storage_handler @set_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, @set_storage_obj.expdate, @set_storage_obj.length, @cache_handler.cas_key, @set_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end

  def test_empty_datablock_set
    reply = @cache_handler.storage_handler @storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @storage_obj_empty.key, @storage_obj_empty.flags, @storage_obj_empty.expdate, @storage_obj_empty.length, @cache_handler.cas_key, @storage_obj_empty.data_block
    assert_equal expected_get, @cache_handler.cache.get(@storage_obj_empty.key)
  end
end