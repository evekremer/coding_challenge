require_relative "../../test_helper"

# Test Memcached::LRUCache class
class LRUCacheTest < BaseTest
  MAX_CAPACITY = 100

  def setup
    @lru_cache = Memcached::LRUCache.new MAX_CAPACITY

    @cas_key = cas_key
    @expdate = Time.new(2021,1,1)
    @key = "#{key}"
    @flags = "#{flags}"
    @data_block = "#{data_block}"
    @length = "#{data_block.length}"

    @full_cache = Memcached::LRUCache.new data_block.length * 10
    @full_cache_keys = Array.new
    10.times{ |i|
      @full_cache_keys[i] = "#{key}#{i}"
      @full_cache.store "#{key}#{i}", @flags, @expdate, @length, @cas_key, @data_block
    }
  end

  ## Test initialize method

  def test_negative_max_capacity
    e = assert_raise ArgumentError do
      Memcached::LRUCache.new -1
    end
    assert_equal Memcached::LRUCache::NEGATIVE_MAX_CAPACITY_ERROR, e.message
  end

  ## Test store method

  def test_simple_store_empty_cache
    @lru_cache.store @key, @flags, @expdate, @length, @cas_key, @data_block
    
    expected = data_to_hash @key, @flags, @expdate, @length, @cas_key, @data_block
    assert_equal expected, @lru_cache.get(@key)
  end

  def test_store_full_cache
    @full_cache.store key, @flags, @expdate, @length, @cas_key, @data_block
    
    # has_expected_keys = true
    # @full_cache_keys.each do |iter_key|
    #   if iter_key == @full_cache_keys[0]
    #     has_expected_keys &= !(@full_cache.has_key? iter_key)
    #   else
    #     has_expected_keys &= @full_cache.has_key? iter_key
    #   end
    # end
    # has_expected_keys &= @full_cache.has_key? key
    
    # assert has_expected_keys
  end

  ## Test get method
end