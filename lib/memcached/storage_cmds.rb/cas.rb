class Memcached::StorageCommand::CasCommand < Memcached::StorageCommand
    include Util
    CAS_PARAMETERS_MAX_LENGTH = 6
    
    def initialize(command_name, command_split, connection, cas_key)
        super(command_name, command_split, connection, CAS_PARAMETERS_MAX_LENGTH)
        validate_cas!(cas_key)

        @cas_key = cas_key
        cas_handler
    end

    private

    # Cas: set the data if it is not updated since last fetch
    def cas_handler
    ####################### SYNCHRO
        cache_has_key = cache_has_key(key)

        unless cache_has_key # The key does not exist in the cache
            message = NOT_FOUND_MSG
        # The item has been modified since last fetch
        elsif cache_has_key && (cache.cas_key(key) != @cas_key.to_i)
            message = EXISTS_MSG
        else
            store_new_item
            message = STORED_MSG
        end
    ####################### SYNCHRO
    end
end