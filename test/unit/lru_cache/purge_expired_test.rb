require_relative "../../test_helper"

# Test purge_expired_keys method for Memcached::LRUCache class
class PurgeExpiredTest < BaseTest
  def setup
    @lru_cache = Memcached::LRUCache.new Memcached::MAX_CACHE_CAPACITY
  end

  def test_simple_purge_expired
    expdate = Time.now
    @lru_cache.store key, flags, expdate, data_block.length, cas_key, data_block

    assert @lru_cache.has_key? key
    @lru_cache.purge_expired_keys
    refute @lru_cache.has_key? key
  end

  def test_simple_purge_not_expired
    @lru_cache.store key, flags, expdate, data_block.length, cas_key, data_block

    assert @lru_cache.has_key? key
    @lru_cache.purge_expired_keys
    assert @lru_cache.has_key? key
  end
  
  def test_purge_expired_empty_cache
    assert_nothing_raised do
      @lru_cache.purge_expired_keys
    end
  end

  def test_store_multi_none_expired
    expdate = Time.now + (30 * Memcached::SECONDS_PER_DAY)

    8.times{ |i|
      @lru_cache.store "#{key}#{i}", flags, expdate, data_block.length, cas_key, data_block
    }

    @lru_cache.purge_expired_keys

    has_expected_keys = true
    8.times{ |i|
      has_expected_keys &= @lru_cache.has_key? "#{key}#{i}"
    }

    assert has_expected_keys
  end

  def test_store_multi_all_expired
    expdate = Time.new(2000, 1, 1)

    8.times{ |i|
      @lru_cache.store "#{key}#{i}", flags, expdate, data_block.length, cas_key, data_block
    }

    @lru_cache.purge_expired_keys
    assert @lru_cache.empty?
  end

  def test_set_multi_some_expired
    expdate_expired = Time.now
    expdate_not_expired = Time.now + 1000

    20.times{ |i|
      if i < 10
        @lru_cache.store "#{key}#{i}", flags, expdate_expired, data_block.length, cas_key, data_block
      else
        @lru_cache.store "#{key}#{i}", flags, expdate_not_expired, data_block.length, cas_key, data_block
      end
    }

    @lru_cache.purge_expired_keys

    has_expected_keys = true
    20.times{ |i|
      if i < 10
        has_expected_keys &= !(@lru_cache.has_key? "#{key}#{i}")
      else
        has_expected_keys &= @lru_cache.has_key? "#{key}#{i}"
      end
    }

    assert has_expected_keys
  end
end