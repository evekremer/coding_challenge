require_relative "../../test_helper"

# Test that inserts with full cache cause older data to be purged in least recently used (LRU) order
# Unit test for Memcached::Server class
class LruServerTest < BaseTest
  DATA_BLOCK = 'd' * (Memcached::MAX_DATA_BLOCK_LENGTH / 2)
  KEY = 'key'

  def self.send_storage_cmd cmd_name, key, flags, exptime, length, unique_cas_key, value, noreply = false
    request = "#{cmd_name} #{key} #{flags} #{exptime} #{length}"
    request += " #{unique_cas_key}" if unique_cas_key
    request += " #{Memcached::NO_REPLY}" if noreply
    request += Memcached::CMD_ENDING

    @socket.puts request
    @socket.puts "#{value}#{Memcached::CMD_ENDING}"
  end

  def self.startup
    @socket = TCPSocket.open( "localhost", 9999 )
    # Reach maximum cache capacity
    ((Memcached::MAX_CACHE_CAPACITY/Memcached::MAX_DATA_BLOCK_LENGTH) * 2).times{ |n|
      self.send_storage_cmd Memcached::SET_CMD_NAME, "#{KEY}#{n}", 5, 300, DATA_BLOCK.length, false, DATA_BLOCK, true
    }
    @socket.close
  end

  @@i = 0
  @@lru_key = "#{KEY}#{@@i}"
  
  def update_lru_key
    @@i += 1
    @@lru_key = "#{KEY}#{@@i}"
  end

  #### Set command

  def test_lru_set
    # Set new item, causes @@lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, false, DATA_BLOCK, true

    send_get_cmd @@lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @@lru_key
    expected_reply = expected_get_response @@lru_key, flags, DATA_BLOCK.length, DATA_BLOCK
    assert_equal expected_reply, read_reply(3)

    update_lru_key
  end

  #### Get command

  def get_lru
    # Fetch @@lru_key: causes @@lru_key to be the current most-recently used
    send_get_cmd @@lru_key
    read_reply(3)
    update_lru_key

    # Reach maximum capacity by setting 'key', causing @@lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, false, DATA_BLOCK, true
    
    send_get_cmd @@lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @@lru_key
    expected_reply = expected_get_response @@lru_key, flags, DATA_BLOCK.length, DATA_BLOCK
    assert_equal expected_reply, read_reply(3)

    update_lru_key
  end

  def test_get_not_lru
    # Fetch not_lru_key: causes not_lru_key to be the current most-recently used
    # and the LRU key must not change after fetch
    not_lru_key = "#{KEY}28"
    send_get_cmd not_lru_key
    read_reply(3)

    # Reach maximum capacity by setting 'key', causing @@lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, false, DATA_BLOCK, true

    send_get_cmd @@lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @@lru_key
    expected_reply = expected_get_response @@lru_key, flags, DATA_BLOCK.length, DATA_BLOCK
    assert_equal expected_reply, read_reply(3)

    update_lru_key
  end

  #### Append command

  def test_lru_append
    # Reach maximum capacity appending "#{KEY}36", causing @@lru_key to be evicted
    send_storage_cmd Memcached::APPEND_CMD_NAME, "#{KEY}36", flags, exptime, DATA_BLOCK.length, false, DATA_BLOCK, true

    send_get_cmd @@lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @@lru_key
    expected_reply = expected_get_response @@lru_key, flags, DATA_BLOCK.length, DATA_BLOCK
    assert_equal expected_reply, read_reply(3)

    update_lru_key
  end

  #### Replace command

  def test_lru_replace
    # Reach maximum capacity replacing "#{KEY}33", causing @@lru_key to be evicted
    data_block = DATA_BLOCK * 2
    send_storage_cmd Memcached::REPLACE_CMD_NAME, "#{KEY}33", flags, exptime, data_block.length, false, data_block, true

    send_get_cmd @@lru_key
    assert_equal Memcached::END_MSG, read_reply

    # Check the current least-recently used item is stored
    update_lru_key

    send_get_cmd @@lru_key
    expected_reply = expected_get_response @@lru_key, flags, DATA_BLOCK.length, DATA_BLOCK
    assert_equal expected_reply, read_reply(3)

    update_lru_key
  end
end
