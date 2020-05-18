module Memcached
  class CacheHandler
    include Mixin

    attr_reader :cache, :cas_key

    def initialize max_cache_capacity = MAX_CACHE_CAPACITY
      @cas_key = 0
      @cache = LRUCache.new max_cache_capacity
      @monitor = SafeSync.new
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
      
      @monitor.start_reading
      reply = ""
      retrieval_obj.keys.each do |key|
        # Keys that do not exists, do not appear into response
        if item = @cache.get(key)
          unless is_expired? item[:expdate]
            reply += "#{VALUE_LABEL}#{key} #{item[:flags]} #{item[:length]}"
            reply += " #{item[:cas_key]}" if retrieval_obj.command_name == GETS_CMD_NAME
            reply += "#{CMD_ENDING}#{item[:data_block]}#{CMD_ENDING}"
          end
        end
      end
      reply += END_MSG
      @monitor.finish_reading
      reply
    end

    def purge_expired_keys
      @monitor.start_writing
      @cache.purge_expired_keys
      @monitor.finish_writing
    end

    private

    # [Add / Replace]:
    # Store data only if the server [does not / does] already hold data for key
    def add_replace(storage_obj)
      @monitor.start_writing

      key = storage_obj.key
      cache_has_key = @cache.has_key? key
      if (!cache_has_key && storage_obj.command_name == ADD_CMD_NAME) || (cache_has_key && storage_obj.command_name == REPLACE_CMD_NAME)
        store_new_item storage_obj
        message = STORED_MSG
      else
        message = NOT_STORED_MSG
      end

      @monitor.finish_writing
      message
    end

    # [Prepend / Append]:
    #  Adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append storage_obj
      
      @monitor.start_writing
      begin
        key = storage_obj.key
        if item = @cache.get(key) # the key exists in cache
          # Prepend/Append previously stored data_block
          previous_data_block = String.new item[:data_block]
          preapp_data_block = String.new storage_obj.data_block

          if storage_obj.command_name == PREPEND_CMD_NAME
            new_data_block = preapp_data_block.concat(previous_data_block)
          else
            new_data_block = previous_data_block.concat(preapp_data_block)
          end

          # Update previously stored length
          previous_length = item[:length].to_i
          preapp_length = storage_obj.length.to_i
          new_length = previous_length + preapp_length

          # New data_block and length validation
          validate_data_block_length! new_length, new_data_block

          # Insert new length, data block and cas key to 'key'
          # Flags and expdate attributes are not modified
          @cache.store key, item[:flags], item[:expdate], new_length.to_s, get_update_cas_key, new_data_block

          message = STORED_MSG
        else
          message = NOT_STORED_MSG
        end
      ensure
        @monitor.finish_writing
      end

      message
    end

    # Cas:
    # Set data only if it is not updated since last fetch
    def cas storage_obj
      @monitor.start_writing
      
      key = storage_obj.key
      if item = @cache.get(key)
        # Store new item if the item has not been modified since last fetch
        if item[:cas_key].to_i != storage_obj.cas_key.to_i
          message = EXISTS_MSG 
        else
          store_new_item storage_obj
          message = STORED_MSG
        end
      else
        message = NOT_FOUND_MSG
      end

      @monitor.finish_writing
      message
    end

    def store_new_item storage_obj
      @cache.store storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, get_update_cas_key, storage_obj.data_block
    end
  end
end