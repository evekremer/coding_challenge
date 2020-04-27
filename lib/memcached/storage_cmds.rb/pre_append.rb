
class Memcached::StorageCommand::PreAppendCommand < Memcached::StorageCommand
    def initialize(command_name, parameters, connection)
        super(command_name, parameters, connection)
        pre_append_handler
    end

    # [Prepend / Append]: adds 'data_block' to an existing key [before / after] existing data_block
    def pre_append_handler
####################### SYNCHRO
        if cache_has_key(key) # the key exists in cache
            
            # Append/prepend previously stored data_block
            previous_item = cache.get(key)

            previous_data_block = previous_item.data_block
            if command_name == PREPEND_CMD_NAME
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
    end
end