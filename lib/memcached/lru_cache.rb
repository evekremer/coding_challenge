module Memcached
  class LRUCache
    include Mixin
    NEGATIVE_MAX_CAPACITY_ERROR = 'max_capacity must not be negative'

    attr_reader :cache

    def initialize max_capacity
      @total_length_stored = 0

      # Maps items to linked list nodes
      # Allows to find an element in the cache's linked list in O(1) time
      @cache = Hash.new

      # Stores the most-recently used item at the head of the list and the least-recently used item at the tail
      # Access LRU element in O(1) time by looking at the tail of the list
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
      if has_key? key
        access key
        @cache[key.to_sym].data
      else
        {}
      end
    end

    def flags key
      @cache[key.to_sym].data[:flags]
    end

    def expdate key
      @cache[key.to_sym].data[:expdate]
    end

    def length key
      if has_key? key
        @cache[key.to_sym].data[:length].to_i
      else
        0
      end
    end

    def cas_key key
      @cache[key.to_sym].data[:cas_key]
    end

    def data_block key
      @cache[key.to_sym].data[:data_block]
    end

    def store key, flags, expdate, length, cas_key, data_block
      # Determine the length added to the total stored
      stored_item_length = length(key)
      added_length = length.to_i - stored_item_length

      # LRU eviction: delete least-recently used item
      # if maximum capacity is reached with the new insertion
      evict_lru if @total_length_stored + added_length > @max_capacity

      # Store new item and update state of cache
      data = {key: key, flags: flags, expdate: expdate, length: length, cas_key: cas_key, data_block: data_block}
      @cache[key.to_sym] = @lru_linked_list.insert_head data
      @total_length_stored += added_length
    end

    def purge_expired_keys
      puts "Purging expired keys ........"
      @cache.each do |key, value|
        if is_expired? value.data[:expdate]
          remove value
        end
      end
    end

    private

    # Set 'key' as the most recently used
    def access key
      @lru_linked_list.update_head @cache[key.to_sym]
    end

    def evict_lru
      tail_node = @lru_linked_list.tail
      return nil unless tail_node
      remove tail_node
    end

    def remove node
      key = node.data[:key]
      @lru_linked_list.remove node
      
      @total_length_stored -= length(key)
      @cache.delete(key.to_sym)
    end
  end
end