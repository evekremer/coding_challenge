# frozen_string_literal: true

module Memcached
  class LRUCache
    include Mixin
    NEGATIVE_MAX_CAPACITY_ERROR = '<max_capacity> must not be negative'

    attr_reader :total_length_stored, :cache, :lru_linked_list, :max_capacity

    def initialize(max_capacity)
      @total_length_stored = 0

      # Maps items to linked list nodes
      # Allows to find an element in the cache's linked list in O(1) time
      @cache = {}

      # Stores the most-recently used item at the head of the list
      #   and the least-recently used item at the tail
      # Access LRU element in O(1) time looking at the tail of the list
      @lru_linked_list = DoublyLinkedList.new

      raise ArgumentError, NEGATIVE_MAX_CAPACITY_ERROR if max_capacity < 1

      @max_capacity = max_capacity
    end

    def key?(key)
      @cache.key? key.to_sym
    end

    def empty?
      @cache.empty?
    end

    def get(key)
      return nil if !key?(key) || value_expired?(key)

      # Set 'key' as the most recently used
      access key

      # Use the hash map to quickly find the corresponding linked list node
      @cache[key.to_sym].data
    end

    def store(key, flags, expdate, length, cas_key, data_block)
      # Determine the length added to the total stored
      stored_item_length = length key
      added_length = length.to_i - stored_item_length

      # Remove least-recently used item from cache
      #   until there is enough free space to store the new item
      evict_lru while @total_length_stored + added_length > @max_capacity

      # Create a new node and insert it at the head of the linked list
      data = { key: key, flags: flags, expdate: expdate.round, length: length, cas_key: cas_key, data_block: data_block }
      node = @lru_linked_list.insert_new_head data

      # Add the item into the hash map
      # storing the newly-created linked list node as the value
      @cache[key.to_sym] = node
      @total_length_stored += added_length
    end

    def purge_expired_keys
      @cache.each do |_key, value|
        remove value if expired? value.data[:expdate]
      end
    end

    private

    def length(key)
      return 0 unless key? key

      @cache[key.to_sym].data[:length].to_i
    end

    def value_expired?(key)
      return nil unless key? key

      expired? @cache[key.to_sym].data[:expdate]
    end

    # Move the item's linked list node to the head of the linked list,
    #   since it is now the most recently used
    def access(key)
      @lru_linked_list.insert_head @cache[key.to_sym]
    end

    # Remove least-recently used item from cache
    def evict_lru
      least_recently_used_node = @lru_linked_list.tail
      remove least_recently_used_node
    end

    # Remove 'node' from the hash map and linked list
    def remove(node)
      key = node.data[:key]

      @total_length_stored -= length key

      @cache.delete key.to_sym
      @lru_linked_list.remove node
    end
  end
end
