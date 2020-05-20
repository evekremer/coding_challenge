# frozen_string_literal: true

module Memcached
  class RetrievalCommand
    include Mixin
    PARAMETERS_MIN_LENGTH_RETRIEVAL = 1

    attr_reader :keys, :command_name

    def initialize(command_name, keys)
      @command_name = command_name.to_s
      @keys = keys

      validate!
    end

    private

    def validate!
      raise ArgumentError unless RETRIEVAL_CMDS.include? command_name

      raise TypeError unless keys.is_a? Array

      validate_parameters_min_length! keys, PARAMETERS_MIN_LENGTH_RETRIEVAL

      @keys.each_with_index do |key, index|
        validate_key! key
        @keys[index] = @keys[index].to_s
      end
    end
  end
end
