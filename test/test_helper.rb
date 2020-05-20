# frozen_string_literal: true

require_relative '../lib/memcached/mixin'
require_relative '../lib/memcached/commands/retrieval'
require_relative '../lib/memcached/commands/storage'
require_relative '../lib/memcached/commands/cas'
require_relative '../lib/memcached/safe_sync'
require_relative '../lib/memcached/cache_handler'
require_relative '../lib/memcached/doubly_linked_list'
require_relative '../lib/memcached/lru_cache'

require 'test/unit'
require 'socket'

class BaseTest < Test::Unit::TestCase
  def key
    'key_' + caller.first[/.*[` ](.*)'/, 1]
  end

  def value
    'value_' + caller.first[/.*[` ](.*)'/, 1]
  end
  alias data_block value

  def new_value
    'new_value'
  end

  def flags
    5
  end

  def exptime
    rand(200..500)
  end

  def expdate
    Time.now + rand(200..500)
  end

  def cas_key
    rand(500)
  end

  def expected_get_response(key, flags, length, value, unique_cas_key = false, multi = false)
    reply = "#{Memcached::VALUE_LABEL}#{key} #{flags} #{length}"
    reply += " #{unique_cas_key}" if unique_cas_key
    reply += Memcached::CMD_ENDING
    reply += "#{value}#{Memcached::CMD_ENDING}"
    reply += Memcached::END_MSG unless multi
    reply
  end

  def data_to_hash(key, flags, expdate, length, cas_key, data_block)
    { key: key, flags: flags, expdate: expdate, length: length, cas_key: cas_key, data_block: data_block }
  end
end

class String
  def titlecase
    gsub(/\w+/, &:capitalize)
  end
end
