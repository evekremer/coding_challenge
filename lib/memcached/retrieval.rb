module Memcached
    class RetrievalCommand < Server
        include Util
        PARAMETERS_MIN_LENGTH_RETRIEVAL = 1
        
        def initialize(command_name, keys = [])
            @cmd_name = command_name
            @keys = keys

            validate!
            retrieve_items
        end

        def keys
            @keys
        end

        # Retrieves the value stored at 'keys'.
        def retrieve_items
            reply = ""
            @keys.each do |key|
        ####################### SYNCHRO
                if cache_has_key(key) # Keys that do not exists, do not appear on the response
                    item = cache.get(key)
                    cache.update_most_recently_used(key)

                    unless item.is_expired?
                        reply += VALUE_LABEL + "#{key} #{item.flags} #{item.length.to_s}"
                        if @cmd_name == GETS_CMD_NAME
                            reply += " #{cas_key}"
                        end
                        reply += CMD_ENDING

                        reply += "#{item.data_block}" + CMD_ENDING
                    end
                end
        ####################### SYNCHRO
            end
            reply += END_MSG
            message = reply
        end

        private

        def validate!
            validate_parameters_min_length!(keys, PARAMETERS_MIN_LENGTH_RETRIEVAL)
            @keys.each do |key|
                validate_key!(key)
            end
        end
    end
end