require_relative "../../test_helper"

# Test retrieval_handler method for CacheHandler class
class RetrievalHandlerTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
  end

  def test_simple_get
    @cache_handler.cache.store key, flags, expdate, data_block.length, @cache_handler.get_update_cas_key, data_block
    
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, ["#{key}"]
    reply = @cache_handler.retrieval_handler retrieval_obj

    expected_reply = expected_get_response key, flags, data_block.length, data_block, false
    
    assert_equal expected_reply, reply
  end

  def test_get_key_not_found
    @cache_handler.cache.store key, flags, expdate, data_block.length, @cache_handler.get_update_cas_key, data_block
    
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, ["#{key}1"]
    reply = @cache_handler.retrieval_handler retrieval_obj
    
    assert_equal Memcached::END_MSG, reply
  end

  def test_simple_gets
    get_update_cas_key = @cache_handler.get_update_cas_key
    @cache_handler.cache.store(key, flags, expdate, data_block.length, get_update_cas_key, data_block)
    
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GETS_CMD_NAME, ["#{key}"]
    reply = @cache_handler.retrieval_handler retrieval_obj
    expected_reply = expected_get_response key, flags, data_block.length, data_block, get_update_cas_key
    
    assert_equal expected_reply, reply
  end

  def test_get_on_empty_cache
    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, ["#{key}"]
    reply = @cache_handler.retrieval_handler retrieval_obj
    
    assert_equal Memcached::END_MSG, reply
  end

  def test_get_multi
    keys = Array.new
    expected_reply = ''
    5.times{ |i|
      # store not expired items
      @cache_handler.cache.store("key#{i}", flags, expdate, data_block.length, @cache_handler.get_update_cas_key, data_block)
      keys[i] = "key#{i}"
      expected_reply += expected_get_response "key#{i}", flags, data_block.length, data_block, false, true
      
      # store expired items
      @cache_handler.cache.store("key_expired#{i + 5}", flags, Time.now, data_block.length, @cache_handler.get_update_cas_key, data_block)
      keys[i+5] = "key_expired#{i + 5}"
    }
    expected_reply += Memcached::END_MSG

    retrieval_obj = Memcached::RetrievalCommand.new Memcached::GET_CMD_NAME, keys
    reply = @cache_handler.retrieval_handler retrieval_obj
    
    assert_equal expected_reply, reply
  end
end