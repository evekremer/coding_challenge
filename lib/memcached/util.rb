module Memcached
  # Response messages
  STORED_MSG = "STORED" + CMD_ENDING
  NOT_STORED_MSG = "NOT_STORED" + CMD_ENDING
  NOT_FOUND_MSG = "NOT_FOUND" + CMD_ENDING
  EXISTS_MSG = "EXISTS" + CMD_ENDING
  INVALID_COMMAND_NAME_MSG = "ERROR" + CMD_ENDING
  END_MSG = "END" + CMD_ENDING

  # Expiration date
  SECONDS_PER_DAY = 60*60*24
  UNIX_TIME = Time.new(1970,1,1)
  
  ONE_MEGABYTE = (2 ** 20)
  KEY_MAX_LENGTH = 250
  DATA_BLOCK_MAX_LENGTH = ONE_MEGABYTE # 1MB
  MAX_CAS_KEY = (2 ** 64) - 1 # 64-bit unsigned int
  MAX_CACHE_CAPACITY = 64 * ONE_MEGABYTE # 64MB

  PURGE_EXPIRED_KEYS_FREQUENCY_SECS = 10

  # Command names
  SET_CMD_NAME = "set"
  ADD_CMD_NAME = "add"
  REPLACE_CMD_NAME = "replace"
  PREPEND_CMD_NAME = "prepend"
  APPEND_CMD_NAME = "append"
  CAS_CMD_NAME = "cas"
  GET_CMD_NAME = "get"
  GETS_CMD_NAME = "gets"
  CMD_ENDING = "\r\n"
  NO_REPLY = "noreply"

  # Response error messages
  CLIENT_ERROR = "CLIENT_ERROR "
  VALUE_LABEL = "VALUE "
  TOO_MANY_ARGUMENTS_MSG = "The command has too many arguments"
  TOO_FEW_ARGUMENTS_MSG = "The command has too few arguments"

  EXPTIME_TYPE_MSG = '<exptime> is not an integer'
  FLAGS_TYPE_MSG = '<flags> is not a 16-bit unsigned integer'
  LENGTH_TYPE_MSG = '<length> is not an unsigned integer'
  CAS_KEY_TYPE_MSG = '<cas_unique> is not a 64-bit unsigned integer'

  CMD_TERMINATION_MSG = "Commands must be terminated by '\\r\n'"

  KEY_NOT_PROVIDED_MSG = '<key> must be provided'
  KEYS_NOT_PROVIDED_MSG = '<key>* must be provided'
  KEY_WITH_CONTROL_CHARS_PROVIDED_MSG = '<key> must not include control characters'

  KEY_TOO_BIG_MSG = "<key> has more than #{MAX_KEY_LENGTH} characters"
  DATA_BLOCK_TOO_BIG_MSG = "<data_block> has more than #{MAX_DATA_BLOCK_LENGTH} characters"

  class ArgumentClientError < StandardError; end
  class TypeClientError < StandardError; end

  module Util
    def validate_key!(key)
      raise TypeClientError, KEY_NOT_PROVIDED unless key != ""
      raise TypeClientError, KEY_WITH_CONTROL_CHARS_PROVIDED_MSG if key.has_control_characters?
      raise TypeClientError, KEY_RANGE_ERROR_MSG unless key.length() <= KEY_MAX_LENGTH
    end

    def validate_exptime!(exptime)
      raise TypeClientError, EXPTIME_TYPE_ERROR unless exptime.is_i?
    end

    def validate_length!(length)
      raise TypeClientError, LENGTH_TYPE_ERROR unless length.is_unsigned_i?
    end

    def validate_flags!(flags)
      raise TypeClientError, FLAGS_TYPE_ERROR unless flags.is_unsigned_i?(16)
    end

    def validate_parameters_min_length!(parameters, min_length)
      raise ArgumentClientError, TOO_FEW_ARGUMENTS unless parameters.length() >= min_length
    end

    def validate_data_block!(length, data_block)
      # Validate that data_block does not exceed maximum length
      raise TypeClientError, DATA_BLOCK_TOO_BIG_MSG unless data_block.length() <= DATA_BLOCK_MAX_LENGTH
      
      # Validate that 'length' parameter corresponds to the actual data_block length
      raise ArgumentClientError, "<length> (#{length}) is not equal to the length of the item's data_block (#{data_block.length()})" unless data_block.length() == length.to_i
    end

    def is_unsigned_i?(num_bits = nil)
      /\A\d+\z/ === self 
      && (num_bits ? self.to_i < 2**num_bits && self.to_i >= 0 : true )
    end

    def is_i?
      /\A[-+]?\d+\z/ === self
    end

    def has_control_characters?
      /\x00|[\cA-\cZ]/ =~ self
    end
  end
end