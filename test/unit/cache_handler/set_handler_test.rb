# frozen_string_literal: true

require_relative 'cache_handler_helper'

# Test store_new_item for CacheHandler class
class SetHandlerTest < CacheHandlerHelper
  def test_simple_set
    parameters = [key.to_s, flags.to_s, exptime.to_s, data_block.length.to_s]
    reply = @cache_handler.new_storage Memcached::SET_CMD_NAME, parameters, data_block
    assert_equal Memcached::STORED_MSG, reply

    assert_get_storage Memcached::SET_CMD_NAME, parameters, data_block
  end

  def test_empty_datablock_set
    parameters_empty = [key.to_s, flags.to_s, exptime.to_s, ''.length.to_s]

    reply = @cache_handler.new_storage Memcached::SET_CMD_NAME, parameters_empty, ''
    assert_equal Memcached::STORED_MSG, reply

    assert_get_storage Memcached::SET_CMD_NAME, parameters_empty, ''
  end
end
