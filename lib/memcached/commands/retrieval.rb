module Memcached
  class RetrievalCommand
    include Util
    PARAMETERS_MIN_LENGTH_RETRIEVAL = 1
    
    def initialize(command_name, keys = [])
      @cmd_name = command_name
      @keys = keys

      validate!
    end

    def keys
      @keys
    end

    def command_name
      @cmd_name
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