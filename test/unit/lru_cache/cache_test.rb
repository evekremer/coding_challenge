require_relative "../../test_helper"

# Test Memcached::LRUCache class
class LRUCacheTest < BaseTest
  MAX_CAPACITY = 100

  def setup
    @lru_cache = Memcached::LRUCache.new MAX_CAPACITY
  end

  def test_negative_max_capacity
    e = assert_raise ArgumentError do
      Memcached::LRUCache.new -1
    end
    assert_equal Memcached::LRUCache::NEGATIVE_MAX_CAPACITY_ERROR, e.message
  end

  def test_simple_store
    @lru_cache.store key, flags, expdate, data_block.length, cas_key, data_block
    
  end

end