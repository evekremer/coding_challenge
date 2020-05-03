module Memcached
  class StorageCommand
    include Util
    PARAMETERS_MAX_LENGTH = 5

    def initialize(command_name, parameters, data_block, parameters_max_length = PARAMETERS_MAX_LENGTH)
      @command_name = command_name.to_s
      validate_command_name! [SET_CMD_NAME, ADD_CMD_NAME, REPLACE_CMD_NAME, CAS_CMD_NAME, PREPEND_CMD_NAME, APPEND_CMD_NAME], command_name

      # max_length: number of maximum parameters expected (excluding command name)
      @parameters_max_length = parameters_max_length.to_i
      validate_number_of_parameters! parameters

      @key, @flags, exptime, @length = parameters
      @data_block = data_block.to_s
      validate_parameters!
      
      @expdate = expiration_date exptime
      @no_reply = has_no_reply? parameters
    end

    def key
      @key
    end

    def flags
      @flags
    end

    def expdate
      @expdate
    end

    def length
      @length
    end

    def data_block
      @data_block
    end

    def no_reply
      @no_reply
    end

    def command_name
      @command_name
    end

    def parameters_max_length
      @parameters_max_length
    end

    private

    # Determine the expiration date corresponding to the <exptime> parameter received
    def expiration_date(exptime)
      validate_exptime! exptime

      expt = exptime.to_i
      case
      when expt == 0 # Never expires 
        expdate = 0
      when expt < 0 # Immediately expired
        expdate = Time.now
      when expt <= 30 * SECONDS_PER_DAY
        expdate = Time.now + expt # Offset from current time
      else
        expdate = UNIX_TIME + expt # Offset from 1/1/1970 (Unix time)
      end
      expdate
    end

    # Determine if the optional "noreply" parameter is included in command
    def has_no_reply?(parameters)
      no_reply = false
      if parameters.length == @parameters_max_length
        raise ArgumentClientError, CLIENT_ERROR + "\"#{NO_REPLY}\" was expected as the #{@parameters_max_length+1}th argument, but \"#{parameters[@parameters_max_length-1]}\" was received" + CMD_ENDING unless parameters[@parameters_max_length-1] == NO_REPLY
        no_reply = true
      end
      no_reply
    end

    def validate_number_of_parameters!(parameters)
      raise TypeError unless parameters.is_a? Array
      validate_parameters_min_length! parameters, parameters_max_length-1
      validate_parameters_max_length! parameters, parameters_max_length
    end

    def validate_parameters!
      @key = @key.to_s
      @flags = @flags.to_s
      @length = @length.to_s

      validate_key! key
      validate_flags! flags
      validate_length! length
      validate_data_block! length, data_block
    end
  end
end