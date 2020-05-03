require_relative "../test_helper"

class ConcurrencyTest < BaseTest
  def test_multiple_threads_set_get
    Array.new(10) do |n|
      Thread.new do
        # Set and get: (key, value) = (k1<n>, v1<n>)
        s = socket
        s.puts "#{Memcached::SET_CMD_NAME} k1_#{n} 2 1000 #{"v1_#{n}".length}#{Memcached::CMD_ENDING}"
        s.puts "v1_#{n}#{Memcached::CMD_ENDING}"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "#{Memcached::GET_CMD_NAME} k1_#{n}#{Memcached::CMD_ENDING}"
        assert_equal "VALUE k1_#{n} 2 #{"v1_#{n}".length}#{Memcached::CMD_ENDING}", s.gets
        assert_equal "v1_#{n}#{Memcached::CMD_ENDING}", s.gets
        assert_equal Memcached::END_MSG, s.gets

        # Set and get: (key, value) = (k2<n>, v2<n>)
        s.puts "#{Memcached::SET_CMD_NAME} k2_#{n} 2 1000 #{"v2_#{n}".length}#{Memcached::CMD_ENDING}"
        s.puts "v2_#{n}#{Memcached::CMD_ENDING}"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "#{Memcached::GET_CMD_NAME} k2_#{n}#{Memcached::CMD_ENDING}"
        assert_equal "VALUE k2_#{n} 2 #{"v2_#{n}".length}#{Memcached::CMD_ENDING}", s.gets
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
          s.puts "#{Memcached::SET_CMD_NAME} test#{n}_#{i} 0 500 #{"v#{n}".length}#{Memcached::CMD_ENDING}"
          s.puts "v#{n}#{Memcached::CMD_ENDING}"
          assert_equal Memcached::STORED_MSG, s.gets
          keys += " test#{n}_#{i}"
        }

        # Get all the previously set keys
        s.puts "#{Memcached::GET_CMD_NAME}" + keys + "#{Memcached::CMD_ENDING}"
        20.times { |i|
          assert_equal "VALUE test#{n}_#{i} 0 #{"v#{n}".length}#{Memcached::CMD_ENDING}", s.gets
          assert_equal "v#{n}#{Memcached::CMD_ENDING}", s.gets
        }
        assert_equal Memcached::END_MSG, s.gets
      end
    end.each(&:join)
  end
end
