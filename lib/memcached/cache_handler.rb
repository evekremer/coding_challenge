# frozen_string_literal: true

module Memcached
  # CacheHandler class
  class CacheHandler
    include Mixin

    attr_reader :cache, :cas_key

    def initialize(max_cache_capacity = MAX_CACHE_CAPACITY)
      @cas_key = 0
      @cache = LRUCache.new max_cache_capacity
      @monitor = SafeSync.new
    end

    def update_cas_key
      @cas_key += 1
      @cas_key = @cas_key.modulo(CAS_KEY_LIMIT)
      @cas_key
    end

    def new_retrieval(command_name, parameters)
      retrieval_obj = RetrievalCommand.new command_name, parameters
      retrieval_handler retrieval_obj
    end

    def new_storage(command_name, parameters, data_block)
      storage_obj = if command_name == CAS_CMD_NAME
                      CasCommand.new parameters, data_block
                    else
                      StorageCommand.new command_name, parameters, data_block
                    end

      message = storage_handler storage_obj
      return NO_REPLY if storage_obj.no_reply

      message
    end

    def purge_expired_keys
      @monitor.start_writing
      @cache.purge_expired_keys
      @monitor.finish_writing
    end

    private

    # Retrieves the value stored at 'keys'
    # Keys that do not exists, do not appear into response
    def retrieval_handler(retrieval_obj)
      @monitor.start_reading
      reply = ''
      retrieval_obj.keys.each do |key|
        next unless (item = @cache.get(key))

        reply += "#{VALUE_LABEL}#{key} #{item[:flags]} #{item[:length]}"
        if retrieval_obj.command_name == GETS_CMD_NAME
          reply += " #{item[:cas_key]}"
        end
        reply += "#{CMD_ENDING}#{item[:data_block]}#{CMD_ENDING}"
      end
      @monitor.finish_reading
      reply += END_MSG
    end

    def storage_handler(storage_obj)
      @monitor.start_writing
      begin
        case storage_obj.command_name
        when SET_CMD_NAME
          store_new_item storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, storage_obj.data_block
        when ADD_CMD_NAME, REPLACE_CMD_NAME
          add_replace storage_obj
        when PREPEND_CMD_NAME, APPEND_CMD_NAME
          pre_append storage_obj
        when CAS_CMD_NAME
          cas storage_obj
        end
      ensure
        @monitor.finish_writing
      end
    end

    # [Add / Replace]:
    # Store data only if the server [does not / does] already hold data for key
    def add_replace(storage_obj)
      cache_has_key = @cache.key? storage_obj.key
      if (!cache_has_key && storage_obj.command_name == ADD_CMD_NAME) || (cache_has_key && storage_obj.command_name == REPLACE_CMD_NAME)
        store_new_item storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, storage_obj.data_block
      else
        NOT_STORED_MSG
      end
    end

    # [Prepend / Append]:
    #  Adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append(storage_obj)
      if (item = @cache.get(storage_obj.key)) # the key exists in cache
        pre_append_storage item, storage_obj
      else
        NOT_STORED_MSG
      end
    end

    def pre_append_storage(item, storage_obj)
      # Prepend/Append previously stored data_block
      previous_data_block = String.new item[:data_block]
      preapp_data_block = String.new storage_obj.data_block

      new_db = if storage_obj.command_name == PREPEND_CMD_NAME
                 preapp_data_block.concat(previous_data_block)
               else
                 previous_data_block.concat(preapp_data_block)
               end

      # Update previously stored length
      new_length = item[:length].to_i + storage_obj.length.to_i

      # New data_block and length validation
      validate_data_block_length! new_length, new_db

      # Insert new length, data block and cas key to 'key'
      # Flags and expdate attributes are not modified
      store_new_item storage_obj.key, item[:flags], item[:expdate], new_length.to_s, new_db
    end

    # Cas:
    # Set data only if it is not updated since last fetch
    def cas(storage_obj)
      if (item = @cache.get(storage_obj.key))
        # Store new item if the item has not been modified since last fetch
        if item[:cas_key].to_i != storage_obj.cas_key.to_i
          EXISTS_MSG
        else
          store_new_item storage_obj.key, storage_obj.flags, storage_obj.expdate, storage_obj.length, storage_obj.data_block
        end
      else
        NOT_FOUND_MSG
      end
    end

    def store_new_item(key, flags, expdate, length, data_block)
      @cache.store key, flags, expdate, length, update_cas_key, data_block
      STORED_MSG
    end
  end
end
