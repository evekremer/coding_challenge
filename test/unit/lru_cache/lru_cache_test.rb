require_relative "../../test_helper"

# Test Memcached::LRUCache class
class LRUCacheTest < BaseTest
  MAX_CAPACITY = 100

  def setup
    @lru_cache = Memcached::LRUCache.new MAX_CAPACITY

    @cas_key = cas_key
    @expdate = Time.new(2021,1,1)
    @flags = "#{flags}"
    @data_block = "#{data_block}"
    @length = "#{data_block.length}"

    t = 10
    @full_cache = Memcached::LRUCache.new data_block.length * t
    @full_cache_keys = Array.new
    t.times{ |i|
      @full_cache_keys[i] = "#{key}#{i}"
      @full_cache.store "#{key}#{i}", @flags, @expdate, @length, @cas_key, @data_block
    }

    @lru_key_index = 0
    @lru_key = @full_cache_keys[@lru_key_index]
  end  

  def update_lru_key
    @lru_key_index += 1
    @lru_key = @full_cache_keys[@lru_key_index]
  end

  def contains_expected_keys cache, keys
    expected_keys = true
    keys.each do |iter_key|
      expected_keys &= cache.has_key? iter_key
    end
    expected_keys
  end

  def check_curent_head_tail cache, mru_key, lru_key
    # Most recently-used key
    check = cache.lru_linked_list.head.data[:key] == mru_key
    # Least recently-used key
    check &= cache.lru_linked_list.tail.data[:key] == lru_key
    check
  end

  ## Test initialize method

  def test_negative_max_capacity
    e = assert_raise ArgumentError do
      Memcached::LRUCache.new -1
    end
    assert_equal Memcached::LRUCache::NEGATIVE_MAX_CAPACITY_ERROR, e.message
  end

  ## Test store method

  def test_simple_store_first_item
    @lru_cache.store key, @flags, @expdate, @length, @cas_key, @data_block

    assert check_curent_head_tail @lru_cache, key, key
    assert_equal @length.to_i, @lru_cache.total_length_stored
  end

  def test_store_empty
    data_block = ''
    length = "#{data_block.length}"
    @lru_cache.store key, @flags, @expdate, length, @cas_key, data_block
    
    expected = data_to_hash key, @flags, @expdate, length, @cas_key, data_block

    assert_equal expected, @lru_cache.get(key)
    assert_equal length.to_i, @lru_cache.total_length_stored
  end

  def test_store_length_int
    @lru_cache.store key, @flags, @expdate, data_block.length, @cas_key, data_block
    
    expected = data_to_hash key, @flags, @expdate, data_block.length, @cas_key, data_block
    assert_equal expected, @lru_cache.get(key)
    assert_equal data_block.length, @lru_cache.total_length_stored
  end

  def test_store_full_cache
    @full_cache.store key, @flags, @expdate, @length, @cas_key, @data_block
   
    # Check current LRU key is purged on new insertion into full cache
    @full_cache_keys.delete @lru_key
    assert contains_expected_keys @full_cache, @full_cache_keys + [key]
    refute @full_cache.has_key? @lru_key
    
    assert check_curent_head_tail @full_cache, key, @full_cache_keys[@lru_key_index]
    assert_equal @full_cache.max_capacity, @full_cache.total_length_stored
  end

  def test_store_full_cache_multiple_evictions
    # The insert of a new item causes more than one item (three) to be evicted
    max_capacity = 100
    full_cache = Memcached::LRUCache.new max_capacity

    # Reach max cache capacity
    data_block = 'd' * 2
    full_cache_keys = Array.new
    
    (max_capacity/data_block.length).times{ |i|
      full_cache_keys[i] = "#{key}#{i}"
      full_cache.store "#{key}#{i}", flags, expdate, data_block.length, @cas_key, data_block
    }

    data_block = data_block * 3
    full_cache.store key, flags, expdate, data_block.length, @cas_key, data_block
   
    # Check current LRU key is purged on new insertion into full cache
    3.times{ |i| full_cache_keys.delete "#{key}#{i}" }
    assert contains_expected_keys full_cache, full_cache_keys + [key]
    
    has_lru_keys = true
    3.times{ |i| has_lru_keys &= full_cache.has_key? "#{key}#{i}" }
    refute has_lru_keys
    
    assert check_curent_head_tail full_cache, key, full_cache_keys[0]
    assert full_cache.max_capacity >= full_cache.total_length_stored
  end

  ## Test get method

  def test_get_empty
    assert_equal nil, @lru_cache.get(key)
  end

  def test_get_first_item
    @lru_cache.store key, @flags, @expdate, @length, @cas_key, @data_block

    expected = data_to_hash key, @flags, @expdate, @length, @cas_key, @data_block
    assert_equal expected, @lru_cache.get(key)
  end

  def test_get_full_cache
    # Fetch least-recently used key
    @full_cache.get @lru_key
    update_lru_key
    
    @full_cache.store key, @flags, @expdate, @length, @cas_key, @data_block

    # Check current LRU key is purged on new insertion into full cache
    @full_cache_keys.delete @lru_key
    assert contains_expected_keys @full_cache, @full_cache_keys + [key]
    refute @full_cache.has_key? @lru_key

    assert check_curent_head_tail @full_cache, key, @full_cache_keys[@lru_key_index]
  end
end