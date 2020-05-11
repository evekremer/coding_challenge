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

    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end

  def test_empty_datablock_set
    reply = @cache_handler.storage_handler @storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = {key: @storage_obj_empty.key, flags: @storage_obj_empty.flags, expdate: @storage_obj_empty.expdate, length: @storage_obj_empty.length, cas_key: @cache_handler.cas_key, data_block: @storage_obj_empty.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@storage_obj_empty.key)
  end
end