require_relative "../test_helper"

class ConcurrencyTest < BaseTest
  def test_multiple_threads_set_get
    Array.new(10) do |n|
      Thread.new do
        # Set and get: (key, value) = (k1<n>, v1<n>)
        s = socket
        s.puts "set k1_#{n} 2 1000 #{"v1_#{n}".length()}\r\n"
        s.puts "v1_#{n}\r\n"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "get k1_#{n}\r\n"
        assert_equal "VALUE k1_#{n} 2 #{"v1_#{n}".length()}\r\n", s.gets
        assert_equal "v1_#{n}\r\n", s.gets
        assert_equal Memcached::END_MSG, s.gets

        # Set and get: (key, value) = (k2<n>, v2<n>)
        s.puts "set k2_#{n} 2 1000 #{"v2_#{n}".length()}\r\n"
        s.puts "v2_#{n}\r\n"
        assert_equal Memcached::STORED_MSG, s.gets

        s.puts "get k2_#{n}\r\n"
        assert_equal "VALUE k2_#{n} 2 #{"v2_#{n}".length()}\r\n", s.gets
        assert_equal "v2_#{n}\r\n", s.gets
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
          s.puts "set test#{n}_#{i} 0 500 #{"v#{n}".length()}\r\n"
          s.puts "v#{n}\r\n"
          assert_equal Memcached::STORED_MSG, s.gets
          keys += " test#{n}_#{i}"
        }

        # Get all the previously set keys
        s.puts "get" + keys + "\r\n"
        20.times { |i|
          assert_equal "VALUE test#{n}_#{i} 0 #{"v#{n}".length()}\r\n", s.gets
          assert_equal "v#{n}\r\n", s.gets
        }
        assert_equal Memcached::END_MSG, s.gets
      end
    end.each(&:join)
  end
end
