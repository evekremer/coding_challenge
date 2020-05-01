module Memcached
  class LRUCache
    def initialize(max_capacity)
      @total_length_stored = 0
      @cache = Hash.new(Hash.new())
      
      raise ArgumentError.new(max_capacity) if max_capacity < 1
      @max_capacity = max_capacity
    end

    def cache
      @cache
    end

    def has_key?(key)
      @cache.has_key?(key.to_sym)
    end

    def get(key)
      @cache[key.to_sym]
      #update_most_recently_used(key)
    end

    def flags(key)
      @cache[key.to_sym][:flags]
    end

    def expdate(key)
      @cache[key.to_sym][:expdate]
    end

    def length=(key, length)
      @cache[key.to_sym][:length] = length
    end

    def length(key)
      if has_key?(key)
        @cache[key.to_sym][:length].to_i
      else
        0
      end
    end

    def cas_key=(key, cas_key)
      @cache[key.to_sym][:cas_key] = cas_key
    end

    def cas_key(key)
      @cache[key.to_sym][:cas_key]
    end

    def data_block=(key, data_block)
      @cache[key.to_sym][:data_block] = data_block
    end

    def data_block(key)
      @cache[key.to_sym][:data_block]
    end

    def store(key, flags, expdate, length, cas_key, data_block)
      # Determine the length added by the new insertion to the total stored
      stored_item_length = length(key)
      added_length = length.to_i - stored_item_length

      # Remove LRU item if maximum capacity is reached
      remove_least_recently_used if @total_length_stored + added_length > @max_capacity

      # Store new item and update state of cache
      @cache[key.to_sym] = {flags: flags, expdate: expdate, length: length, cas_key: cas_key, data_block: data_block}
      
      @total_length_stored += added_length
      update_most_recently_used(key)
      STORED_MSG
    end

    def remove_item_from_cache(key)
      @total_length_stored -= length(key)
      @cache.delete(key.to_sym)
    end

    private

    def update_most_recently_used(key)
      # Mark 'key' as the most recently used
      # ...
    end

    def remove_least_recently_used
      remove_item_from_cache(key)
      # ...
    end
  end
end