module Memcached
  class CacheHandler
    include Mixin

    def initialize max_cache_capacity = MAX_CACHE_CAPACITY
      @cas_key = 0
      @cache = LRUCache.new max_cache_capacity
    end

    def cache
      @cache
    end

    def cas_key
      @cas_key
    end

    def get_update_cas_key
      @cas_key += 1
      @cas_key = @cas_key.modulo(CAS_KEY_LIMIT)
      @cas_key
    end

    def storage_handler storage_obj

      case storage_obj.command_name

      when SET_CMD_NAME
        store_new_item storage_obj
        message = STORED_MSG

      when ADD_CMD_NAME, REPLACE_CMD_NAME
        message = add_replace storage_obj

      when PREPEND_CMD_NAME, APPEND_CMD_NAME
        message = pre_append storage_obj

      when CAS_CMD_NAME
        message = cas storage_obj
      end

      message
    end

    # Retrieves the value stored at 'keys'
    def retrieval_handler retrieval_obj
      reply = ""
      retrieval_obj.keys.each do |key|
      ################### SYNCHRO
      if @cache.has_key? key # Keys that do not exists, do not appear on the response
        item = @cache.get key

        unless is_expired? item[:expdate]
          reply += "#{VALUE_LABEL}#{key} #{item[:flags]} #{item[:length]}"
          if retrieval_obj.command_name == GETS_CMD_NAME
            reply += " #{item[:cas_key]}"
          end
          reply += CMD_ENDING

          reply += "#{item[:data_block]}#{CMD_ENDING}"
        end
      end
      ################## SYNCHRO
      end
      reply += END_MSG
      reply
    end

    def purge_expired_keys
      puts "Purging expired keys ........"
      ####################### SYNCHRO
      @cache.cache.each do |key, value|
        if is_expired? value[:expdate]
          @cache.remove_item_from_cache key
        end
      end
      ####################### SYNCHRO
    end

    private

    # [Add / Replace]: store data only if the server [does not / does] already hold data for key
    def add_replace(storage_obj)
      key = storage_obj.key

      ####################### SYNCHRO
      cache_has_key = @cache.has_key? key

      if (!cache_has_key && storage_obj.command_name == ADD_CMD_NAME) || (cache_has_key && storage_obj.command_name == REPLACE_CMD_NAME)
        store_new_item storage_obj
        message = STORED_MSG
      else
        message = NOT_STORED_MSG
      end
      ####################### SYNCHRO
      message
    end

    # [Prepend / Append]: adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append storage_obj
      key = storage_obj.key

      ####################### SYNCHRO
      if @cache.has_key? key # the key exists in cache

        previous_data_block = String.new @cache.data_block key
        preapp_data_block = String.new storage_obj.data_block

        if storage_obj.command_name == PREPEND_CMD_NAME
          new_data_block = preapp_data_block.concat(previous_data_block)
        elsif storage_obj.command_name == APPEND_CMD_NAME
          new_data_block = previous_data_block.concat(preapp_data_block)
        end

        previous_length = @cache.length key
        preapp_length = storage_obj.length.to_i
        new_length = previous_length + preapp_length

        validate_data_block_length! new_length, new_data_block

        @cache.store key, @cache.flags(key), @cache.expdate(key), new_length.to_s, get_update_cas_key, new_data_block
        message = STORED_MSG
      else
        message = NOT_STORED_MSG
      end
      ####################### SYNCHRO
      message
    end

    # Cas: set the data if it is not updated since last fetch
    def cas storage_obj
      key = storage_obj.key

      ####################### SYNCHRO
      if @cache.has_key? key
        if @cache.cas_key(key).to_i != storage_obj.cas_key.to_i
          message = EXISTS_MSG # The item has been modified since last fetch
        else
          store_new_item storage_obj
          message = STORED_MSG
        end
      else
        message = NOT_FOUND_MSG
      end
      ####################### SYNCHRO
      message
    end

    def store_new_item storage_obj
      @cache.store storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, get_update_cas_key, storage_obj.data_block
    end
  end
end