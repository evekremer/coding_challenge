require_relative 'item'

class Memcached::LRUCache
  def initialize(max_capacity)
    @total_length_stored = 0
    @cache = Hash.new
    
    raise ArgumentError.new(max_capacity) if @max_capacity < 1
    @max_capacity = max_capacity
  end

  def get(key)
    @cache[key]
    update_most_recently_used(key)
  end

  def cache_has_key?(key)
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

  def store(key, new_item)
    # Determine the length added by the new insertion to the total stored
    previous_item_length = length(key)
    added_length = new_item.length.to_i - previous_item_length

    # Remove LRU item if maximum capacity is reached
    remove_least_recently_used if @total_length_stored + added_length > @max_capacity

    # Store new item and update state of cache
    @cache[key] = new_item
    @total_length_stored += added_length
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

  private

  def update_most_recently_used(key)
    # Mark 'key' as the most recently used
    # ...
  end

  def remove_item_from_cache(key)
    deleted_item = @cache.delete(key)
    @total_length_stored -= deleted_item[1].length.to_i
  end

  def remove_least_recently_used
    remove_item_from_cache(key)
    # ...
  end
end