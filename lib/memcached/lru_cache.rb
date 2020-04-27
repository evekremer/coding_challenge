require_relative 'item'

class Memcached::LRUCache
    def initialize(max_cache_capacity, max_cas_key)
        @cas_key = 0
        @total_length_stored = 0
        @cache = Hash.new
        @max_capacity = max_cache_capacity
        @max_cas_key = max_cas_key
    end

    def get(key)
        @cache[key]
    end

    def cache_has_key(key)
        @cache.has_key?(key)
    end

    def length(key)
        if cache_has_key(key)
            @cache[key].length
        else
            0
        end
    end

    def data_block(key)
        @cache[key].data_block
    end

    def cas_key(key)
        @cache[key].cas_key
    end

    def cas_key
        @cas_key
    end

    def store_item(key, item, added_length)
        # Remove LRU item if maximum capacity is reached
        remove_least_recently_used if @total_length_stored + added_length > @max_capacity
        
        # Store new item and update global variables
        item.cas_key = cas_key
        @cache[key] = item
        update_global_variables(added_length)
        update_most_recently_used(key)
    end

    
    def purge_expired_keys
####################### SYNCHRO
        @cache.each do |key, value|
            if value.is_expired?
                remove_item_from_cache(key)
            end
        end
####################### SYNCHRO
    end

    def update_most_recently_used(key)
        # Mark 'key' as the most recently used
        # ...
    end

    private
    
    # Update global cas key and total length stored after a new insertion
    def update_global_variables(added_length)
        @total_length_stored += added_length
        @cas_key += 1
        @cas_key = (@cas_key).modulo(@max_cas_key)
    end

    def remove_item_from_cache(key)
        deleted_item = @cache.delete(key)
        @total_length_stored -= deleted_item[1].length
    end

    def remove_least_recently_used
        remove_item_from_cache(key)
        # ...
    end
end