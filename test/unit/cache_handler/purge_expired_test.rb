require_relative "../../test_helper"

# Test purge_expired_keys method for CacheHandler class
class PurgeExpiredTest < BaseTest
  def setup
    @cache_handler = Memcached::CacheHandler.new
  end

  def test_simple_purge_expired
    expdate = Time.now
    @cache_handler.cache.store(key, flags, expdate, data_block.length, @cache_handler.global_cas_key, data_block)

    assert @cache_handler.cache.has_key? key

    @cache_handler.purge_expired_keys

    # Delete expired item
    refute @cache_handler.cache.has_key? key
  end

  def test_simple_purge_not_expired
    expdate = Time.now + 1000
    @cache_handler.cache.store(key, flags, expdate, data_block.length, @cache_handler.global_cas_key, data_block)

    assert @cache_handler.cache.has_key? key

    @cache_handler.purge_expired_keys

    # Keep not expired item
    assert @cache_handler.cache.has_key? key
  end
  
  def test_purge_expired_empty_cache
    assert_nothing_raised do
      @cache_handler.purge_expired_keys
    end
  end

  def test_store_multi_none_expired
    expdate = Time.now + (30 * Memcached::SECONDS_PER_DAY)

    8.times{ |i|
      @cache_handler.cache.store("#{key}#{i}", flags, expdate, data_block.length, @cache_handler.global_cas_key, data_block)
    }

    @cache_handler.purge_expired_keys

    has_expected_keys = true
    8.times{ |i|
      has_expected_keys &= @cache_handler.cache.has_key? "#{key}#{i}"
    }

    assert has_expected_keys
  end

  def test_store_multi_all_expired
    expdate = Time.new(2000, 1, 1)

    8.times{ |i|
      @cache_handler.cache.store("#{key}#{i}", flags, expdate, data_block.length, @cache_handler.global_cas_key, data_block)
    }

    @cache_handler.purge_expired_keys
    assert @cache_handler.cache.empty?
  end

  def test_set_multi_some_expired
    expdate_expired = Time.now
    expdate_not_expired = Time.now + 1000

    20.times{ |i|
      if i < 10
        @cache_handler.cache.store("#{key}#{i}", flags, expdate_expired, data_block.length, @cache_handler.global_cas_key, data_block)
      else
        @cache_handler.cache.store("#{key}#{i}", flags, expdate_not_expired, data_block.length, @cache_handler.global_cas_key, data_block)
      end
    }

    @cache_handler.purge_expired_keys

    has_expected_keys = true
    20.times{ |i|
      if i < 10
        has_expected_keys &= !(@cache_handler.cache.has_key? "#{key}#{i}")
      else
        has_expected_keys &= @cache_handler.cache.has_key? "#{key}#{i}"
      end
    }

    assert has_expected_keys
  end
end