# frozen_string_literal: true

module Memcached
  class CasCommand < StorageCommand
    attr_reader :cas_key

    def initialize(parameters, data_block)
      super(CAS_CMD_NAME, parameters, data_block, CAS_CMD_PARAMETERS_MAX_LENGTH)

      @cas_key = parameters[4].to_s
      validate_cas!
    end

    private

    def validate_cas!
      return if unsigned_i? cas_key, CAS_KEY_LIMIT

      raise TypeClientError, CAS_KEY_TYPE_MSG
    end
  end
end
