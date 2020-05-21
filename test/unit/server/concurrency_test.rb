# frozen_string_literal: true

require_relative 'server_test_helper'

# Unit test for Memcached::Server class
class ServerConcurrencyTest < ServerTestHelper
  def test_multiple_threads_set_get
    testPass = true
    Array.new(10) do |n|
      Thread.new do
        # Set and get: (key, value) = (k1<n>, v1<n>)
        s = socket
        s.puts "#{Memcached::SET_CMD_NAME} k1_#{n} #{flags} #{exptime} #{"v1_#{n}".length}#{Memcached::CMD_ENDING}"
        s.puts "v1_#{n}#{Memcached::CMD_ENDING}"
        testPass &= (Memcached::STORED_MSG == s.gets)

        s.puts "#{Memcached::GET_CMD_NAME} k1_#{n}#{Memcached::CMD_ENDING}"
        testPass &= (s.gets == "#{Memcached::VALUE_LABEL}k1_#{n} #{flags} #{"v1_#{n}".length}#{Memcached::CMD_ENDING}")
        testPass &= (s.gets == "v1_#{n}#{Memcached::CMD_ENDING}")
        testPass &= (Memcached::END_MSG == s.gets)
      end
    end.each(&:join)
    assert testPass
  end

  def test_threads_with_get_multi_keys
    testPass = true
    Array.new(10) do |n|
      Thread.new do
        s = socket
        keys = ''
        # Set 20 items with (key, value) = (test#{n}#{i}, v#{n})
        20.times do |i|
          s.puts "#{Memcached::SET_CMD_NAME} test#{n}_#{i} #{flags} #{exptime} #{"v#{n}".length}#{Memcached::CMD_ENDING}"
          s.puts "v#{n}#{Memcached::CMD_ENDING}"
          testPass &= (Memcached::STORED_MSG == s.gets)
          keys += " test#{n}_#{i}"
        end

        # Get all the previously set keys
        s.puts Memcached::GET_CMD_NAME.to_s + keys + Memcached::CMD_ENDING.to_s
        20.times do |i|
          testPass &= (s.gets == "#{Memcached::VALUE_LABEL}test#{n}_#{i} #{flags} #{"v#{n}".length}#{Memcached::CMD_ENDING}")
          testPass &= (s.gets == "v#{n}#{Memcached::CMD_ENDING}")
        end
        testPass &= (Memcached::END_MSG == s.gets)
      end
    end.each(&:join)
    assert testPass
  end
end
