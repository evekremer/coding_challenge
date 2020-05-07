require_relative "../test_helper"

# Test that inserts with full cache cause older data to be purged in least recently used (LRU) order

class ServerLruTest < BaseTest
  def test_lru
    ##########     Set     ##########

    # Reach maximum capacity
    # The last item causes the first inserted item to be purged
    v = "v" * (Memcached::MAX_DATA_BLOCK_LENGTH)
    65.times{ |n|
        send_storage_cmd("set", "key#{n}", 2, 3000, v.length(), false, v, false)
        read_reply
    }

    # Check that the first inserted item (key0) was purged
    reply = send_get_cmd("key0")
    assert_equal Memcached::END_MSG, reply

    # Fetch key1: causes key1 (the LRU item) to be the current most recently used item
    reply = send_get_cmd("key1")
    assert_equal expected_get_response("key1", 2, v.length(), v), reply

    # Add new item: causes the third inserted item (key2) to be purged
    send_storage_cmd("set", "a"+key, 2, 3000, v.length(), false, v, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Check that the third inserted item (key2) was purged
    reply = send_get_cmd("key2")
    assert_equal Memcached::END_MSG, reply

    ##########     Append    ##########
    
    # Total space left: 0

    v2 = "v" * (Memcached::MAX_DATA_BLOCK_LENGTH - 4)
    send_storage_cmd("set", "key_prepend_test", 2, 3000, v2.length(), false, v2, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key3 was purged
    reply = send_get_cmd("key3")
    assert_equal Memcached::END_MSG, reply

    # Reach maximum capacity appending v3 to v2: causes key4 to be purged
    v3 = "v" * 4
    send_storage_cmd("append", "key_prepend_test", 2, 3000, v3.length(), false, v3, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key4 was purged
    reply = send_get_cmd("key4")
    assert_equal Memcached::END_MSG, reply

    ##########     Replace     ##########
    #=> Total space left: MAX_DATA_BLOCK_LENGTH
    send_storage_cmd("set", "new_key", 2, 3000, v3.length(), false, v3, false)
    assert_equal Memcached::STORED_MSG, read_reply

    #=> Total space left: MAX_DATA_BLOCK_LENGTH - 4

    # Set different key with length = 4
    send_storage_cmd("set", "key_replace_test", 2, 3000, v3.length(), false, v3, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Fetch key5: causes key5 (the LRU item) to be the current most recently used item
    reply = send_get_cmd("key5")
    assert_equal expected_get_response("key5", 2, v.length(), v), reply

    # Reach maximum capacity by replacing "key_replace_test" with length = MAX_DATA_BLOCK_LENGTH:
    # Causes key6 to be purged
    send_storage_cmd("replace", "key_replace_test", 2, 3000, v.length(), false, v, false)
    assert_equal Memcached::STORED_MSG, read_reply

    # Check key6 was purged
    reply = send_get_cmd("key6")
    assert_equal Memcached::END_MSG, reply
  end
end
