require_relative "../../test_helper"

# Test that inserts with full cache cause older data to be purged in least recently used (LRU) order
class LruServerTest < BaseTest
  def setup
    @v = 'v' * Memcached::MAX_DATA_BLOCK_LENGTH
    @key = 'key'
    # Reach maximum cache capacity
    (Memcached::MAX_CACHE_CAPACITY/Memcached::MAX_DATA_BLOCK_LENGTH).times{ |n|
      send_storage_cmd Memcached::SET_CMD_NAME, "#{@key}#{n}", flags, exptime, @v.length, false, @v, true
    }
    @v3 = 'v' * 4
    @v2 = 'v' * (Memcached::MAX_DATA_BLOCK_LENGTH - @v3.length)
    
    @i = 0
    @lru_key = "#{@key}#{@i}"
  end

  def update_lru_key
    @i += 1
    @lru_key = "#{@key}#{@i}"
  end

  #### Set command

  def test_lru_set
    # Set new item, causes @lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, @v.length, false, @v, true

    send_get_cmd @lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @lru_key
    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)
  end

  #### Get command

  def test_get_lru
    # Fetch @lru_key: causes @lru_key to be the current most-recently used
    send_get_cmd @lru_key
    update_lru_key

    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)

    # Reach maximum capacity by setting 'key', causing @lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, @v.length, false, @v, true

    send_get_cmd @lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @lru_key
    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)
  end

  def test_get_not_lru
    # Fetch not_lru_key: causes not_lru_key to be the current most-recently used
    # and the LRU key must not change after fetch
    not_lru_key = "#{@key}5"

    send_get_cmd not_lru_key
    expected_reply = expected_get_response not_lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)

    # Reach maximum capacity by setting 'key', causing @lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, @v.length, false, @v, true

    send_get_cmd @lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @lru_key
    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)
  end

  #### Append command

  def test_lru_append
    # Reach maximum capacity by setting 'key', causing @lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, @v2.length, false, @v2, true
    update_lru_key

    # Reach maximum capacity by appending 'key', causing @lru_key to be evicted
    send_storage_cmd Memcached::APPEND_CMD_NAME, key, flags, exptime, @v3.length, false, @v3, true

    send_get_cmd @lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @lru_key
    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)
  end

  #### Replace command

  def test_lru_replace
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, @v3.length, false, @v3, true
    update_lru_key

    # Reach maximum capacity by replacing @v3 with @v
    send_storage_cmd Memcached::REPLACE_CMD_NAME, key, flags, exptime, @v.length, false, @v, true
    update_lru_key

    send_get_cmd @lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @lru_key
    expected_reply = expected_get_response @lru_key, flags, @v.length, @v
    assert_equal expected_reply, read_reply(3)
  end
end
