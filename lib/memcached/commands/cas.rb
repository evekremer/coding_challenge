module Memcached
  class CasCommand < StorageCommand
    attr_reader :cas_key

    def initialize parameters, data_block
      super(CAS_CMD_NAME, parameters, data_block, CAS_CMD_PARAMETERS_MAX_LENGTH)
      
      @cas_key = parameters[4].to_s
      validate_cas!
    end

    private

    def validate_cas!
      raise TypeClientError, CAS_KEY_TYPE_MSG unless is_unsigned_i? cas_key, CAS_KEY_LIMIT
    end
  end
end