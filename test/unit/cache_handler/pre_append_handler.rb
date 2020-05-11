require_relative "../../test_helper"

# Test pre_append method for CacheHandler class
class SetHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
    
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block
    @cache_handler.storage_handler @set_storage_obj

    data_block = 'pre_append'
    parameters = ["#{key}", "#{flags + 2}", "#{exptime + 200}", "#{data_block.length}"]
    @prepend_storage_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    @append_storage_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
  end

  # Prepend

  def test_simple_prepend
    reply = @cache_handler.storage_handler @prepend_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    new_data_block =  @prepend_storage_obj.data_block + @set_storage_obj.data_block
    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: new_data_block.length.to_s, cas_key: @cache_handler.cas_key, data_block: new_data_block}
    assert_equal expected_get, @cache_handler.cache.get(@prepend_storage_obj.key)
  end

  def test_missing_key_prepend
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    prepend_storage_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler prepend_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    expected_get = {}
    assert_equal expected_get, @cache_handler.cache.get(prepend_storage_obj.key)
  end

  def test_empty_prepend
    data_block = ''
    parameters = ["#{@set_storage_obj.key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    
    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end

  def test_data_block_too_long_prepend
    # Prepending the existing value exceeds max length
    data_block = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - @set_storage_obj.length.to_i + 1)
    parameters = ["#{@set_storage_obj.key}", "#{flags + 5}", "#{exptime + 200}", "#{data_block.length}"]
    prepend_obj = Memcached::StorageCommand.new Memcached::PREPEND_CMD_NAME, parameters, data_block
    
    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.storage_handler prepend_obj
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end

  # Append

  def test_simple_append
    reply = @cache_handler.storage_handler @append_storage_obj
    assert_equal Memcached::STORED_MSG, reply

    new_data_block =  @set_storage_obj.data_block + @append_storage_obj.data_block
    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: new_data_block.length.to_s, cas_key: @cache_handler.cas_key, data_block: new_data_block}
    assert_equal expected_get, @cache_handler.cache.get(@append_storage_obj.key)
  end

  def test_missing_key_append
    parameters = ["#{key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    append_storage_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
    reply = @cache_handler.storage_handler append_storage_obj
    assert_equal Memcached::NOT_STORED_MSG, reply

    expected_get = {}
    assert_equal expected_get, @cache_handler.cache.get(append_storage_obj.key)
  end

  def test_empty_append
    data_block = ''
    parameters = ["#{@set_storage_obj.key}", "#{flags}", "#{exptime}", "#{data_block.length}"]
    storage_obj_empty = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
    
    reply = @cache_handler.storage_handler storage_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(storage_obj_empty.key)
  end

  def test_data_block_too_long_append
    # Appending the existing value exceeds max length
    data_block = 'b' * (Memcached::MAX_DATA_BLOCK_LENGTH - @set_storage_obj.length.to_i + 1)
    parameters = ["#{@set_storage_obj.key}", "#{flags + 5}", "#{exptime + 200}", "#{data_block.length}"]
    prepend_obj = Memcached::StorageCommand.new Memcached::APPEND_CMD_NAME, parameters, data_block
    
    exception = assert_raise Memcached::TypeClientError do
      @cache_handler.storage_handler prepend_obj
    end
    assert_equal Memcached::DATA_BLOCK_TOO_LONG_MSG, exception.message

    expected_get = {key: @set_storage_obj.key, flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@set_storage_obj.key)
  end
end