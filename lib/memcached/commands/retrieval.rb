module Memcached
  class RetrievalCommand
    include Util
    PARAMETERS_MIN_LENGTH_RETRIEVAL = 1
    
    def initialize(command_name, keys)
      @command_name = command_name.to_s
      @keys = keys

      validate!
    end

    def keys
      @keys
    end

    def command_name
      @command_name
    end

    private

    def validate!
      validate_command_name! [GET_CMD_NAME, GETS_CMD_NAME], command_name
      
      raise TypeError unless keys.is_a? Array
      validate_parameters_min_length! keys, PARAMETERS_MIN_LENGTH_RETRIEVAL
      
      @keys.each_with_index do |key, index|
        validate_key! key
        @keys[index] = @keys[index].to_s
      end
    end
  end
end