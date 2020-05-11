require_relative "../../test_helper"

# Test that inserts with full cache cause older data to be purged in least recently used (LRU) order
class ServerLruTest < BaseTest
  def setup
    # Reach maximum capacity
    # The last item causes the first inserted item to be purged
    @v = 'v' * Memcached::MAX_DATA_BLOCK_LENGTH
    65.times{ |n|
      send_storage_cmd Memcached::SET_CMD_NAME, "key#{n}", flags, exptime, @v.length, false, @v, true
    }
    @v2 = 'v' * (Memcached::MAX_DATA_BLOCK_LENGTH - 4)
    @v3 = 'v' * 4
  end

  def test_lru
    ##########     Set     ##########
    # Check that the first inserted item (key0) was purged
    send_get_cmd "key0"
    assert_equal Memcached::END_MSG, read_reply

    # Fetch key1: causes key1 (the LRU item) to be the current most recently used item
    send_get_cmd "key1"
    expected_reply = expected_get_response "key1", flags, @v.length, @v
    assert_equal expected_reply, read_reply

    # Add new item: causes the third inserted item (key2) to be purged
    send_storage_cmd Memcached::SET_CMD_NAME, "a"+key, flags, exptime, @v.length, false, @v, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Check that the third inserted item (key2) was purged
    send_get_cmd "key2"
    assert_equal Memcached::END_MSG, read_reply

    ##########     Append    ##########
    
    # Total space left: 0
    send_storage_cmd Memcached::SET_CMD_NAME, "key_prepend_test", flags, exptime, @v2.length, false, @v2, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key3 was purged
    send_get_cmd "key3"
    assert_equal Memcached::END_MSG, read_reply

    # Reach maximum capacity appending v3 to v2: causes key4 to be purged
    send_storage_cmd Memcached::APPEND_CMD_NAME, "key_prepend_test", flags, exptime, @v3.length, false, @v3, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key4 was purged
    send_get_cmd "key4"
    assert_equal Memcached::END_MSG, read_reply

    ##########     Replace     ##########
    #=> Total space left: MAX_DATA_BLOCK_LENGTH
    send_storage_cmd Memcached::SET_CMD_NAME, "new_key", flags, exptime, @v3.length, false, @v3, false
    assert_equal Memcached::STORED_MSG, read_reply

    #=> Total space left: MAX_DATA_BLOCK_LENGTH - 4

    # Set different key with length = 4
    send_storage_cmd Memcached::SET_CMD_NAME, "key_replace_test", flags, exptime, @v3.length, false, @v3, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Fetch key5: causes key5 (the LRU item) to be the current most recently used item
    send_get_cmd "key5"
    expected_reply = expected_get_response "key5", flags, @v.length, @v
    assert_equal expected_reply, read_reply

    # Reach maximum capacity by replacing "key_replace_test" with length = MAX_DATA_BLOCK_LENGTH:
    # Causes key6 to be purged
    send_storage_cmd Memcached::REPLACE_CMD_NAME, "key_replace_test", flags, exptime, @v.length, false, @v, false
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key6 was purged
    send_get_cmd "key6"
    assert_equal Memcached::END_MSG, read_reply
  end
end
