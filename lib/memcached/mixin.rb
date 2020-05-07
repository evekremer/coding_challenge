module Memcached
  # Response messages
  CMD_ENDING = "\r\n"
  STORED_MSG = 'STORED' + CMD_ENDING
  NOT_STORED_MSG = 'NOT_STORED' + CMD_ENDING
  NOT_FOUND_MSG = 'NOT_FOUND' + CMD_ENDING
  EXISTS_MSG = 'EXISTS' + CMD_ENDING
  INVALID_COMMAND_NAME_MSG = 'ERROR' + CMD_ENDING
  END_MSG = 'END' + CMD_ENDING

  # Expiration date
  SECONDS_PER_DAY = 60 * 60 * 24
  UNIX_TIME = Time.new 1970, 1, 1
  
  ONE_MEGABYTE = 2 ** 20
  MAX_KEY_LENGTH = 250
  MAX_DATA_BLOCK_LENGTH = ONE_MEGABYTE # 1MB

  CAS_KEY_LIMIT = 2 ** 64 - 1 # 64-bit unsigned int
  FLAGS_LIMIT = 2 ** 16 - 1 # 16-bit unsigned int

  MAX_CACHE_CAPACITY = 64 * ONE_MEGABYTE # 64MB

  PURGE_EXPIRED_KEYS_FREQUENCY_SECS = 10

  # Command names
  SET_CMD_NAME = 'set'
  ADD_CMD_NAME = 'add'
  REPLACE_CMD_NAME = 'replace'
  PREPEND_CMD_NAME = 'prepend'
  APPEND_CMD_NAME = 'append'
  CAS_CMD_NAME = 'cas'
  GET_CMD_NAME = 'get'
  GETS_CMD_NAME = 'gets'
  
  STORAGE_CMDS = [SET_CMD_NAME, ADD_CMD_NAME, REPLACE_CMD_NAME, CAS_CMD_NAME, PREPEND_CMD_NAME, APPEND_CMD_NAME]
  RETRIEVAL_CMDS = [GET_CMD_NAME, GETS_CMD_NAME]

  NO_REPLY = 'noreply'

  # Response error messages
  CLIENT_ERROR = 'CLIENT_ERROR '
  VALUE_LABEL = 'VALUE '
  TOO_MANY_ARGUMENTS_MSG = CLIENT_ERROR + 'The command has too many arguments' + CMD_ENDING
  TOO_FEW_ARGUMENTS_MSG = CLIENT_ERROR + 'The command has too few arguments' + CMD_ENDING

  EXPTIME_TYPE_MSG = CLIENT_ERROR + '<exptime> is not an integer' + CMD_ENDING
  FLAGS_TYPE_MSG = CLIENT_ERROR + '<flags> is not a 16-bit unsigned integer' + CMD_ENDING
  LENGTH_TYPE_MSG = CLIENT_ERROR + '<length> is not an unsigned integer' + CMD_ENDING
  CAS_KEY_TYPE_MSG = CLIENT_ERROR + '<cas_unique> is not a 64-bit unsigned integer' + CMD_ENDING

  CMD_TERMINATION_MSG = CLIENT_ERROR + 'Commands must be terminated by "\r\n"' + CMD_ENDING

  KEY_NOT_PROVIDED_MSG = CLIENT_ERROR + '<key> must be provided' + CMD_ENDING
  KEYS_NOT_PROVIDED_MSG = CLIENT_ERROR + '<key>* must be provided' + CMD_ENDING
  KEY_WITH_CONTROL_CHARS_MSG = CLIENT_ERROR + '<key> must not include control characters' + CMD_ENDING

  KEY_TOO_LONG_MSG = "#{CLIENT_ERROR}<key> has more than #{MAX_KEY_LENGTH} characters#{CMD_ENDING}"
  DATA_BLOCK_TOO_LONG_MSG =  "#{CLIENT_ERROR}<data_block> has more than #{MAX_DATA_BLOCK_LENGTH} characters#{CMD_ENDING}"

  CAS_CMD_PARAMETERS_MAX_LENGTH = 6
  STORAGE_CMD_PARAMETERS_MAX_LENGTH = 5

  class ArgumentClientError < StandardError; end
  class TypeClientError < StandardError; end

  module Mixin
    def data_block_length_error_msg(length, data_block)
      "#{CLIENT_ERROR}<length> (#{length}) is not equal to the length of the item's data_block (#{data_block.length})#{CMD_ENDING}"
    end
  
    def no_reply_syntax_error_msg(parameter_received, parameters_max_length)
      "#{CLIENT_ERROR}\"#{NO_REPLY}\" was expected as the #{parameters_max_length+1}th argument, but \"#{parameter_received}\" was received#{CMD_ENDING}"
    end
    
    def validate_key! key
      raise TypeClientError, KEY_NOT_PROVIDED_MSG if key.to_s.empty?
      raise TypeClientError, KEY_WITH_CONTROL_CHARS_MSG if contains_control_characters? key
      raise TypeClientError, KEY_TOO_LONG_MSG unless key.to_s.length <= MAX_KEY_LENGTH
    end

    def validate_exptime! exptime
      raise TypeClientError, EXPTIME_TYPE_MSG unless is_i? exptime
    end

    def validate_length! length
      raise TypeClientError, LENGTH_TYPE_MSG unless is_unsigned_i? length
    end

    def validate_flags! flags
      raise TypeClientError, FLAGS_TYPE_MSG unless is_unsigned_i? flags, FLAGS_LIMIT
    end

    def validate_parameters_min_length! parameters, min_length
      parameters = Array(parameters)
      raise ArgumentClientError, TOO_FEW_ARGUMENTS_MSG unless parameters.length >= min_length
    end

    def validate_parameters_max_length! parameters, max_length
      parameters = Array(parameters)
      raise ArgumentClientError, TOO_MANY_ARGUMENTS_MSG unless parameters.length <= max_length
    end

    def validate_data_block_length! length, data_block
      data_block = String(data_block)
      length = Integer(length)

      # Validate that data_block does not exceed maximum length
      raise TypeClientError, DATA_BLOCK_TOO_LONG_MSG unless data_block.length <= MAX_DATA_BLOCK_LENGTH
      
      # Validate that 'length' parameter corresponds to the actual data_block length
      raise ArgumentClientError, (data_block_length_error_msg length, data_block)  unless data_block.length == length
    end
    
    def validate_and_remove_ending! command
      raise TypeError unless command.is_a? String

      command_ending = command[-2..-1] || command
      raise ArgumentClientError, CMD_TERMINATION_MSG unless command_ending == CMD_ENDING
      
      command[0..-3]
    end

    def is_unsigned_i? data, limit = nil
      is_unsigned_int = /\A\d+\z/ =~ data.to_s

      if is_unsigned_int && limit && limit_int = Integer(limit)
        data_int = Integer data
        is_inside_bounds = data_int < limit_int
      else
        is_inside_bounds = true
      end

      is_unsigned_int && is_inside_bounds
    end

    def is_i? data
      /\A[-+]?\d+\z/ =~ data.to_s
    end

    def contains_control_characters? data
      /\x00|[\cA-\cZ]/ =~ data.to_s
    end

    def is_expired? time

      if time.is_a? Time
        is_expired = time <= Time.now
      else # never expires 
        time_ = Integer time
        raise ArgumentError unless time_ == 0
        is_expired = false
      end
      
      is_expired
    end
  end
end