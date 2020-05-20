# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test retrieval_handler method for CacheHandler class
class RetrievalHandlerTest < CacheHandlerHelper
  def test_simple_get
    @cache_handler.cache.store key, flags, expdate, data_block.length, @cache_handler.update_cas_key, data_block

    reply = @cache_handler.new_retrieval Memcached::GET_CMD_NAME, [key.to_s]
    expected_reply = expected_get_response key, flags, data_block.length, data_block
    assert_equal expected_reply, reply
  end

  def test_get_key_not_found
    @cache_handler.cache.store key, flags, expdate, data_block.length, @cache_handler.update_cas_key, data_block

    reply = @cache_handler.new_retrieval Memcached::GET_CMD_NAME, ["#{key}1"]
    assert_equal Memcached::END_MSG, reply
  end

  def test_simple_gets
    update_cas_key = @cache_handler.update_cas_key
    @cache_handler.cache.store(key, flags, expdate, data_block.length, update_cas_key, data_block)

    reply = @cache_handler.new_retrieval Memcached::GETS_CMD_NAME, [key.to_s]
    expected_reply = expected_get_response key, flags, data_block.length, data_block, update_cas_key
    assert_equal expected_reply, reply
  end

  def test_get_on_empty_cache
    reply = @cache_handler.new_retrieval Memcached::GET_CMD_NAME, [key.to_s]
    assert_equal Memcached::END_MSG, reply
  end

  def test_get_multi
    keys = []
    expected_reply = ''
    5.times do |i|
      # store not expired items
      @cache_handler.cache.store("key#{i}", flags, expdate, data_block.length, @cache_handler.update_cas_key, data_block)
      keys[i] = "key#{i}"
      expected_reply += expected_get_response "key#{i}", flags, data_block.length, data_block, false, true

      # store expired items
      @cache_handler.cache.store("key_expired#{i + 5}", flags, Time.now, data_block.length, @cache_handler.update_cas_key, data_block)
      keys[i + 5] = "key_expired#{i + 5}"
    end
    expected_reply += Memcached::END_MSG

    reply = @cache_handler.new_retrieval Memcached::GET_CMD_NAME, keys
    assert_equal expected_reply, reply
  end
end
