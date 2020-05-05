require_relative "../test_helper"

class ConcurrencyTest < BaseTest
  def test_multiple_threads_set_get
    Array.new(10) do |n|
      Thread.new do
        # Set and get: (key, value) = (k1<n>, v1<n>)
        s = socket
        s.puts "#{Memcached::SET_CMD_NAME} k1_#{n} #{flags} #{exptime} #{"v1_#{n}".length}#{Memcached::CMD_ENDING}"
        s.puts "v1_#{n}#{Memcached::CMD_ENDING}"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "#{Memcached::GET_CMD_NAME} k1_#{n}#{Memcached::CMD_ENDING}"
        assert_equal "#{Memcached::VALUE_LABEL}k1_#{n} #{flags} #{"v1_#{n}".length}#{Memcached::CMD_ENDING}", s.gets
        assert_equal "v1_#{n}#{Memcached::CMD_ENDING}", s.gets
        assert_equal Memcached::END_MSG, s.gets

        # Set and get: (key, value) = (k2<n>, v2<n>)
        s.puts "#{Memcached::SET_CMD_NAME} k2_#{n} #{flags} #{exptime} #{"v2_#{n}".length}#{Memcached::CMD_ENDING}"
        s.puts "v2_#{n}#{Memcached::CMD_ENDING}"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "#{Memcached::GET_CMD_NAME} k2_#{n}#{Memcached::CMD_ENDING}"
        assert_equal "#{Memcached::VALUE_LABEL}k2_#{n} #{flags} #{"v2_#{n}".length}#{Memcached::CMD_ENDING}", s.gets
        assert_equal "v2_#{n}#{Memcached::CMD_ENDING}", s.gets
        assert_equal Memcached::END_MSG, s.gets
      end
    end.each(&:join)
  end

  def test_threads_with_get_multi_keys
    Array.new(10) do |n|
      Thread.new do
        s = socket
        keys = ""
        # Set 20 items with (key, value) = (test#{n}#{i}, v#{n})
        20.times { |i|
          s.puts "#{Memcached::SET_CMD_NAME} test#{n}_#{i} #{flags} #{exptime} #{"v#{n}".length}#{Memcached::CMD_ENDING}"
          s.puts "v#{n}#{Memcached::CMD_ENDING}"
          assert_equal Memcached::STORED_MSG, s.gets
          keys += " test#{n}_#{i}"
        }

        # Get all the previously set keys
        s.puts "#{Memcached::GET_CMD_NAME}" + keys + "#{Memcached::CMD_ENDING}"
        20.times { |i|
          assert_equal "#{Memcached::VALUE_LABEL}test#{n}_#{i} #{flags} #{"v#{n}".length}#{Memcached::CMD_ENDING}", s.gets
          assert_equal "v#{n}#{Memcached::CMD_ENDING}", s.gets
        }
        assert_equal Memcached::END_MSG, s.gets
      end
    end.each(&:join)
  end
end
