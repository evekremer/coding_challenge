require_relative "../../test_helper"

# Test cas method for CacheHandler class
class SetHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
    
    exptime_ = exptime
    parameters = ["#{key}", "#{flags}", "#{exptime_}", "#{data_block.length}"]
    @set_storage_obj = Memcached::StorageCommand.new Memcached::SET_CMD_NAME, parameters, data_block
    @cache_handler.storage_handler @set_storage_obj

    # Different parameters except for 'key' as @set_storage_obj
    data_block = 'cas_data_block_1'
    parameters = ["#{key}", "#{flags+1}", "#{exptime_+100}", "#{data_block.length}", "#{@cache_handler.cas_key}"]
    @cas_obj_stored = Memcached::CasCommand.new parameters, data_block

    # Different cas_key (only) from @cas_obj_stored
    parameters = ["#{key}", "#{flags+1}", "#{exptime_+100}", "#{data_block.length}", "#{@cache_handler.cas_key+7}"]
    @cas_obj_exists = Memcached::CasCommand.new parameters, data_block

    # Different parameteres from @set_storage_obj
    data_block = 'cas_data_block_2'
    parameters = ["#{key}_", "#{flags+4}", "#{exptime_+200}", "#{data_block.length}", "#{@cache_handler.cas_key}"]
    @cas_obj_not_found = Memcached::CasCommand.new parameters, data_block

    # Same parameters as cas_obj_stored, but with empty data_block
    data_block = ''
    parameters = ["#{key}", "#{flags+1}", "#{exptime_+100}", "#{data_block.length}", "#{@cache_handler.cas_key}"]
    @cas_obj_empty = Memcached::CasCommand.new parameters, data_block
  end

  def test_stored_cas
    reply = @cache_handler.storage_handler @cas_obj_stored
    assert_equal Memcached::STORED_MSG, reply

    expected_get = {flags: @cas_obj_stored.flags, expdate: @cas_obj_stored.expdate, length: @cas_obj_stored.length, cas_key: @cache_handler.cas_key, data_block: @cas_obj_stored.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_stored.key)
  end

  def test_exists_cas
    reply = @cache_handler.storage_handler @cas_obj_exists
    assert_equal Memcached::EXISTS_MSG, reply

    expected_get = {flags: @set_storage_obj.flags, expdate: @set_storage_obj.expdate, length: @set_storage_obj.length, cas_key: @cache_handler.cas_key, data_block: @set_storage_obj.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_exists.key)
  end

  def test_not_found_cas
    reply = @cache_handler.storage_handler @cas_obj_not_found
    assert_equal Memcached::NOT_FOUND_MSG, reply

    expected_get = {}
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_not_found.key)
  end

  def test_empty_data_block_cas
    reply = @cache_handler.storage_handler @cas_obj_empty
    assert_equal Memcached::STORED_MSG, reply

    expected_get = {flags: @cas_obj_empty.flags, expdate: @cas_obj_empty.expdate, length: @cas_obj_empty.length, cas_key: @cache_handler.cas_key, data_block: @cas_obj_empty.data_block}
    assert_equal expected_get, @cache_handler.cache.get(@cas_obj_empty.key)
  end
end