module Memcached
  class CacheHandler
    def initialize(max_cache_capacity = MAX_CACHE_CAPACITY)
      @cas_key = 0
      @cache = LRUCache.new(max_cache_capacity)
      purge_expired_keys
    end

    def cache_has_key?(key)
      @cache.cache_has_key?(key)
    end

    def cache
      @cache
    end

    def storage_handler(storage_obj)
      case storage_obj.command_name
      when SET_CMD_NAME
        message = store_new_item(storage_obj)
      when ADD_CMD_NAME, REPLACE_CMD_NAME
        message = add_replace(storage_obj)
      when PREPEND_CMD_NAME, APPEND_CMD_NAME
        message = pre_append(storage_obj)
      when CAS_CMD_NAME
        message = cas(storage_obj)
      end
      message
    end

    # Retrieves the value stored at 'keys'.
    def retrieval_handler(retrieval_obj)
      reply = ""
      retrieval_obj.keys.each do |key|
      ################### SYNCHRO
        if cache_has_key?(key) # Keys that do not exists, do not appear on the response
          item = cache.get(key)

          unless item.is_expired?
            reply += VALUE_LABEL + "#{key} #{item.flags} #{item.length}"
            if retrieval_obj.command_name == GETS_CMD_NAME
              reply += " #{item.cas_key}"
            end
            reply += CMD_ENDING

            reply += "#{item.data_block}" + CMD_ENDING
          end
        end
      ################## SYNCHRO
      end
      reply += END_MSG
      reply
    end

    def cas_key
      @cas_key
    end

    private

    # [Prepend / Append]: adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append(storage_obj)
      ####################### SYNCHRO
      if cache_has_key?(key) # the key exists in cache
        # Append/prepend previously stored data_block
        previous_item = cache.get(key)
  
        previous_data_block = previous_item.data_block
        if @command_name == PREPEND_CMD_NAME
          new_data_block = data_block.concat(previous_data_block)
        else
          new_data_block = previous_data_block.concat(data_block))
        end
  
        # Check that the length added does not exceed maximum length
        validate_data_block_max_length!(new_data_block)
  
        # Update data_block and length of the stored item
        previous_item.data_block = new_data_block
        previous_item.length = previous_item.length + length.to_i
        message = STORED_MSG
      else
        message = NOT_STORED_MSG
      end
      ####################### SYNCHRO
      message
    end

    # [Add / Replace]: store data only if the server [does not / does] already hold data for key
    def add_replace(storage_obj)
      ####################### SYNCHRO
      cache_has_key = cache_has_key?(key)

      if (!cache_has_key && @command_name == ADD_CMD_NAME)
        || (cache_has_key && @command_name == REPLACE_CMD_NAME)
        message = store_new_item(storage_obj)
      else
        message = NOT_STORED_MSG
      end
      ####################### SYNCHRO
      message
    end


    # Cas: set the data if it is not updated since last fetch
    def cas(storage_obj)
    ####################### SYNCHRO
      cache_has_key = cache_has_key?(key)
  
      unless cache_has_key # The key does not exist in the cache
        message = NOT_FOUND_MSG
      # The item has been modified since last fetch
      elsif cache_has_key && (cache.cas_key(key) != storage_obj.cas_key)
        message = EXISTS_MSG
      else
        message = store_new_item(storage_obj)
      end
      message
    ####################### SYNCHRO
    end

    def store_new_item(storage_obj)
      new_item = Memcached::Item.new(storage_obj.flags, storage_obj.expdate, storage_obj.length, storage_obj.data_block, cas_key)
      update_global_cas_key

      @cache.store(key, new_item)
      message = STORED_MSG
    end

    def update_global_cas_key
      @cas_key += 1
      @cas_key = (@cas_key).modulo(MAX_CAS_KEY)
    end

    def purge_expired_keys
      Thread.new do
        loop{
          sleep(PURGE_EXPIRED_KEYS_FREQUENCY_SECS)
          @cache.purge_expired_keys
        }.join
      end
    end
  end
end