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

    def global_cas_key
      @cas_key += 1
      @cas_key = (@cas_key).modulo(MAX_CAS_KEY)
      @cas_key
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
          flags, expdate, length, cas_key, data_block = cache.get(key)

          unless expdate.is_expired?
            reply += VALUE_LABEL + "#{key} #{flags} #{length.to_s}"
            if retrieval_obj.command_name == GETS_CMD_NAME
              reply += " #{cas_key}"
            end
            reply += CMD_ENDING

            reply += "#{data_block}" + CMD_ENDING
          end
        end
      ################## SYNCHRO
      end
      reply += END_MSG
      reply
    end

    private

    # [Prepend / Append]: adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append(storage_obj)
      key = storage_obj.key

      ####################### SYNCHRO
      if cache_has_key?(key) # the key exists in cache
        # Append/prepend previously stored data_block
        previous_db = cache.data_block(key)
        preapp_db = storage_obj.data_block

        if @command_name == PREPEND_CMD_NAME
          new_data_block = preapp_db.concat(previous_db)
        else
          new_data_block = previous_db.concat(preapp_db)
        end

        previous_length = cache.length(key)
        preapp_length = storage_obj.length.to_i
        new_length = previous_length + preapp_length

        validate_data_block!(new_length, new_data_block)
        
        message = @cache.update(key, new_length, global_cas_key, new_data_block)
      else
        message = NOT_STORED_MSG
      end
      ####################### SYNCHRO
      message
    end

    # [Add / Replace]: store data only if the server [does not / does] already hold data for key
    def add_replace(storage_obj)
      key = storage_obj.key

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
      key = storage_obj.key

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
      ####################### SYNCHRO
      message
      
    end

    def store_new_item(storage_obj)
      message = @cache.store(storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, global_cas_key, storage_obj.data_block)
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