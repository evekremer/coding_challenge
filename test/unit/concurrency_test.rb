require_relative "../test_helper"

class ConcurrencyTest < BaseTest

  def test_multiple_threads_set_get
    Array.new(12) do |n|
      Thread.new do
        # Set and get: (key, value) = (k1<n>, v1<n>)
        socket.puts "set k1#{n} 0 1000 #{n.to_s.length()+2} noreply\r\n"
        socket.puts "v1#{n}\r\n"
        socket.puts "get k1#{n}"
      
        assert_equal "VALUE k1#{n} 0 #{n.to_s.length()+2}\r\n", socket.gets
        assert_equal "v1#{n}\r\n", socket.gets
        assert_equal END_MSG, socket.gets

        # Set and get: (key, value) = (k2<n>, v2<n>)
        socket.puts "set k2#{n} 0 1000 #{n.to_s.length()+2} noreply\r\n"
        socket.puts "v2#{n}\r\n"
        socket.puts "get k2#{n}"

        assert_equal "VALUE k2#{n} 0 #{n.to_s.length()+2}\r\n", socket.gets
        assert_equal "v2#{n}\r\n", socket.gets
        assert_equal END_MSG, socket.gets
      end
    end.each(&:join)
  end

  def test_threads_with_get_multi_keys
    Array.new(12) do |n|
      Thread.new do
        # Set 50 items with (key, value) = (test#{n}#{i}, v#{n})
        50.times { |i|
          socket.puts "set test#{n}#{i} 0 1000 #{n.length()+1} noreply\r\n"
          socket.puts "v#{n}\r\n"
          keys += " test#{n}#{i}"
        }
        
        # Get all the previously set keys
        socket.puts "get" + keys + "\r\n"
        50.times { |i|
          assert_equal "VALUE test#{n}#{i} 0 #{n.length()+1}\r\n", socket.gets
          assert_equal "v#{n}\r\n", socket.gets
        }
        assert_equal END_MSG, socket.gets
      end
    end.each(&:join)
  end
end
