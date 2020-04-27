class Memcached::StorageCommand::AddReplaceCommand < Memcached::StorageCommand
    def initialize(command_name, command_split, connection)
        super(command_name, command_split, connection)
        add_replace_handler
    end

    private

    # [Add / Replace]: store data only if the server [does not / does] already hold data for key
    def add_replace_handler
        ####################### SYNCHRO
        cache_has_key = cache_has_key(key)

        if (!cache_has_key && command_name == ADD_CMD_NAME)
            || (cache_has_key && command_name == REPLACE_CMD_NAME)
            store_new_item
        else
            message = NOT_STORED_MSG
        end
        ####################### SYNCHRO
    end
    
end