require_relative "../../test_helper"

# Test add_replace method for CacheHandler class
class AddReplaceHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
    
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block

    data_block = 'add_replace'
    parameters = ["#{key}", "#{flags+1}", "#{exptime+100}", "#{data_block.length}"]
    @add_storage_obj = Memcached::StorageCommand.new Memcached::ADD_CMD_NAME, parameters, data_block
    @replace_storage_obj = Memcached::StorageCommand.new Memcached::REPLACE_CMD_NAME, parameters, data_block
  end

  # Add

  def test_simple_add
    reply = @cache_handler.storage_handler @add_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @add_storage_obj.key, @add_storage_obj.flags, @add_storage_obj.expdate, @add_storage_obj.length, @cache_handler.cas_key, @add_storage_obj.data_block
    assert_equal expected_get, @cache_handler.cache.get(@add_storage_obj.key)
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
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
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
    parameters = ["#{@set_storage_obj.key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::REPLACE_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = data_to_hash @set_storage_obj.key, @set_storage_obj.flags, storage_obj_empty.expdate, storage_obj_empty.length, @cache_handler.cas_key, storage_obj_empty.data_block
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end
end