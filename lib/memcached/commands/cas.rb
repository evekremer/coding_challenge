module Memcached
  class CasCommand < StorageCommand
    CAS_PARAMETERS_MAX_LENGTH = 6

    def initialize(parameters, data_block)
      super(CAS_CMD_NAME, parameters, data_block, CAS_PARAMETERS_MAX_LENGTH)
      
      validate_cas! parameters[4]
      @cas_key = parameters[4]
    end

    def cas_key
      @cas_key
    end

    private

    def validate_cas!(cas_key)
      raise TypeClientError, CAS_KEY_TYPE_MSG unless is_unsigned_i? cas_key, 64
    end
  end
end