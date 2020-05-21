# frozen_string_literal: true

module Memcached
  # Datatype for storage command requests,
  # encapsulates parameter validation
  class StorageCommand
    include Mixin

    attr_reader :key, :flags, :expdate, :length, :data_block, :no_reply
    attr_reader :command_name, :parameters_max_length

    def initialize(command_name, parameters, data_block,
                   parameters_max_length = STORAGE_CMD_PARAMETERS_MAX_LENGTH)
      @command_name = command_name.to_s
      raise ArgumentError unless STORAGE_CMDS.include? command_name

      # max_length: number of max parameters expected (excluding command name)
      @parameters_max_length = parameters_max_length.to_i
      validate_number_of_parameters! parameters

      @key, @flags, exptime, @length = parameters
      @data_block = data_block.to_s
      validate_parameters!

      @expdate = expiration_date exptime
      @expdate = @expdate.round
      @no_reply = no_reply? parameters
    end

    private

    # Determine the expiration date corresponding to the <exptime> parameter
    def expiration_date(exptime)
      validate_exptime! exptime

      expt = exptime.to_i
      return 0 if expt.zero? # Never expires
      return Time.now if expt.negative? # Immediately expired

      # Offset from current time
      return (Time.now + expt) if expt <= 30 * SECONDS_PER_DAY
      return (UNIX_TIME + expt) if expt > 30 * SECONDS_PER_DAY

      nil
    end

    # Determine if the optional NO_REPLY parameter is included in command
    def no_reply?(parameters)
      return false unless parameters.length == @parameters_max_length

      no_reply = parameters[@parameters_max_length - 1]
      return true if no_reply == NO_REPLY

      error_msg = no_reply_syntax_error_msg no_reply, parameters_max_length
      raise ArgumentClientError, error_msg
    end

    def validate_number_of_parameters!(parameters)
      raise TypeError unless parameters.is_a? Array

      validate_parameters_min_length! parameters, parameters_max_length - 1
      validate_parameters_max_length! parameters, parameters_max_length
    end

    def validate_parameters!
      @key = @key.to_s
      @flags = @flags.to_s
      @length = @length.to_s

      validate_key! key
      validate_flags! flags
      validate_length! length
      validate_data_block_length! length, data_block
    end
  end
end
