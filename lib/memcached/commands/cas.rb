class Memcached::StorageCommand::CasCommand < Memcached::StorageCommand
  CAS_PARAMETERS_MAX_LENGTH = 6

  def initialize(parameters, data_block)
    super(parameters, data_block, CAS_PARAMETERS_MAX_LENGTH)
    
    @cas_key = parameters[4]
    validate_cas_key!
  end

  private

  def validate_cas!(cas_key)
    raise TypeClientError, CAS_KEY_TYPE_ERROR unless @cas_key.is_unsigned_i?(64)
  end
end