require_relative 'item'

class Memcached::LRUCache
  def initialize(max_capacity)
    @total_length_stored = 0
    @cache = Hash.new
    
    raise ArgumentError.new(max_capacity) if @max_capacity < 1
    @max_capacity = max_capacity
  end

  def cache_has_key?(key)
    @cache.has_key?(key)
  end

  def get(key)
    @cache[key]
    update_most_recently_used(key)
  end

  def flags(key)
    @cache[key][0]
  end

  def expdate(key)
    @cache[key][1]
  end

  def length=(key, length)
    @cache[key][2] = length
  end

  def length(key)
    if cache_has_key(key)
      @cache[key][2].to_i
    else
      0
    end
  end

  def cas_key=(key, cas_key)
    @cache[key][3] = cas_key
  end

  def cas_key(key)
    @cache[key][3]
  end

  def data_block=(key, data_block)
    @cache[key][4] = data_block
  end

  def data_block(key)
    @cache[key][4]
  end

  def store(key, flags, expdate, length, cas_key, data_block)
    # Determine the length added by the new insertion to the total stored
    stored_item_length = length(key)
    added_length = length.to_i - stored_item_length

    # Remove LRU item if maximum capacity is reached
    remove_least_recently_used if @total_length_stored + added_length > @max_capacity

    # Store new item and update state of cache
    @cache[key] = flags, expdate, length, cas_key, data_block
    
    @total_length_stored += added_length
    update_most_recently_used(key)
    STORED_MSG
  end

  def update(key, length, cas_key, data_block)
    store(key, flags(key), expdate(key), length, cas_key, data_block)
  end
  
  def purge_expired_keys
####################### SYNCHRO
    @cache.each do |key|
      expdate = expdate(key)
      if expdate.is_expired?
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
    @total_length_stored -= length(key)
    @cache.delete(key)
  end

  def remove_least_recently_used
    remove_item_from_cache(key)
    # ...
  end
end