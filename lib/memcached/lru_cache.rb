module Memcached
  class LRUCache
    include Mixin
    NEGATIVE_MAX_CAPACITY_ERROR = '<max_capacity> must not be negative'

    attr_reader :total_length_stored, :cache, :lru_linked_list, :max_capacity

    def initialize max_capacity
      @total_length_stored = 0

      # Maps items to linked list nodes
      # Allows to find an element in the cache's linked list in O(1) time
      @cache = Hash.new

      # Stores the most-recently used item at the head of the list and the least-recently used item at the tail
      # Access LRU element in O(1) time looking at the tail of the list
      @lru_linked_list = DoublyLinkedList.new
      
      raise ArgumentError.new(NEGATIVE_MAX_CAPACITY_ERROR) if max_capacity < 1
      @max_capacity = max_capacity
    end

    def has_key? key
      @cache.has_key? key.to_sym
    end

    def empty?
      @cache.empty?
    end

    def get key
      return nil unless has_key? key
      
      access key
      @cache[key.to_sym].data
    end

    def store key, flags, expdate, length, cas_key, data_block
      # Determine the length added to the total stored
      stored_item_length = length key
      added_length = length.to_i - stored_item_length

      # Delete least-recently used items
      # if maximum capacity is reached by storing the new item
      while @total_length_stored + added_length > @max_capacity
        evict_lru
      end

      # Store new item and update state of cache
      data = {key: key, flags: flags, expdate: expdate, length: length, cas_key: cas_key, data_block: data_block}
      node = @lru_linked_list.insert_new_head data
      @cache[key.to_sym] = node

      @total_length_stored += added_length
    end

    def purge_expired_keys
      @cache.each do |key, value|
        if is_expired? value.data[:expdate]
          remove value
        end
      end
    end

    private

    def length key
      return 0 unless has_key? key

      @cache[key.to_sym].data[:length].to_i
    end

    # Set 'key' as the most recently used
    def access key
      @lru_linked_list.insert_head @cache[key.to_sym]
    end

    # Remove least-recently used from cache
    def evict_lru
puts "EVICTING----------------------- #{@lru_linked_list.tail.data[:key]}"
      remove @lru_linked_list.tail
    end

    def remove node
      key = node.data[:key]
      
      @total_length_stored -= length key
      @cache.delete key.to_sym

      @lru_linked_list.remove node
    end
  end
end