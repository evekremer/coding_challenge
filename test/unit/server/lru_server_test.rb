# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class

# Test that inserts with full cache cause older data to be purged
# in least recently used (LRU) order
class LruServerTest < ServerTestHelper
  DATA_BLOCK = 'd' * (Memcached::MAX_DATA_BLOCK_LENGTH / 2)
  KEY = 'key'

  def self.store_lru(cmd_name, key, flags, exptime, value)
    request = "#{cmd_name} #{key} #{flags} #{exptime} #{value.length} #{Memcached::NO_REPLY}"
    request += Memcached::CMD_ENDING

    @socket.puts request
    @socket.puts "#{value}#{Memcached::CMD_ENDING}"
  end

  def self.startup
    @socket = TCPSocket.open(SOCKET_ADDRESS, SOCKET_PORT)
    # Reach maximum cache capacity
    t = (Memcached::MAX_CACHE_CAPACITY / DATA_BLOCK.length)
    t.times do |n|
      store_lru Memcached::SET_CMD_NAME, "#{KEY}#{n}", 5, 300, DATA_BLOCK
    end
    @socket.close
    sleep 2
  end

  @@i = 0
  @@lru_key = "#{KEY}#{@@i}"

  def update_lru_key
    @@i += 1
    @@lru_key = "#{KEY}#{i}"
  end

  def lru_key
    @@lru_key
  end

  def i
    @@i
  end

  # Assert current least-recently used item is properly stored
  def check_current_lru
    update_lru_key
    assert_multine_get lru_key, flags, DATA_BLOCK
    update_lru_key
  end

  #### Set command

  def test_lru_set
    # Set new item, causes least-recently used key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, DATA_BLOCK, true
    assert_get lru_key, Memcached::END_MSG

    check_current_lru
  end

  #### Get command

  def test_get_lru
    # Fetch lru_key: causes lru_key to be the current most-recently used
    send_get_cmd lru_key
    read_reply(3)
    update_lru_key

    # Reach maximum capacity by setting 'key', causing lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, DATA_BLOCK, true

    assert_get lru_key, Memcached::END_MSG
    check_current_lru
  end

  def test_get_not_lru
    # Fetch not_lru_key: causes not_lru_key to be the current most-recently used
    # and the LRU key must not change after fetch
    not_lru_key = "#{KEY}28"
    send_get_cmd not_lru_key
    read_reply(3)

    # Reach maximum capacity by setting 'key', causing lru_key to be evicted
    send_storage_cmd Memcached::SET_CMD_NAME, key, flags, exptime, DATA_BLOCK.length, DATA_BLOCK, true

    assert_get lru_key, Memcached::END_MSG
    check_current_lru
  end

  #### Append command

  def test_lru_append
    # Reach maximum capacity appending "#{KEY}36", causing lru_key to be evicted
    send_storage_cmd Memcached::APPEND_CMD_NAME, "#{KEY}36", flags, exptime, DATA_BLOCK.length, DATA_BLOCK, true
    assert_get lru_key, Memcached::END_MSG
    check_current_lru
  end

  #### Replace command

  def test_lru_replace
    # Reach maximum capacity replacing "#{KEY}33", causing lru_key to be evicted
    data_block = DATA_BLOCK * 2
    send_storage_cmd Memcached::REPLACE_CMD_NAME, "#{KEY}33", flags, exptime, data_block.length, data_block, true
    assert_get lru_key, Memcached::END_MSG
    check_current_lru
  end
end
