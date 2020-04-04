require_relative "../test_helper"

class GetGetsTest < BaseTest
  ###########     Get     ###########
  def test_simple_get
    cache.set "key1", "value1"
    assert_equal "value1", cache.get("key1")

    cache.set key, @value
    assert_equal @value, cache.get(key)
  end

  def test_get_nil
    cache.set key, nil, ttl:  0
    result = cache.get(key)
    assert_equal nil, result
  end
  
  def test_get_missing
    assert_nil cache.get "#{key}/#{SecureRandom.hex}"
  end

  def test_get_coerces_string_type
    assert_raise(TypeError) do
      cache.get nil
    end

    assert_raise(TypeError) do
      cache.get 1
    end
  end

  def test_get_with_prefix_key
    # Prefix_key
    cache = Memcached::Client.new(
      # We can only use one server because the key is hashed separately from the prefix key
      @servers.first,
      :prefix_key => @prefix_key,
      :hash => :default,
      :distribution => :modula
    )
    cache.set key, @value
    assert_equal @value, cache.get(key)

    # No prefix_key specified
    cache = Memcached::Client.new(
      @servers.first,
      :hash => :default,
      :distribution => :modula
    )
    assert_equal @value, cache.get("#{@prefix_key}#{key}")
  end

  def test_get_multi
    cache.set "#{key}_1", 1
    cache.set "#{key}_2", 2

    assert_equal({"#{key}_1" => 1, "#{key}_2" => 2},
                  cache.get_multi(["#{key}_1", "#{key}_2"]))
  end

  def test_get_multi_missing
    keys = 4.times.map { |n| "#{key}/#{n}" }
    cache.set keys[0], 1
    cache.set keys[1], 3
    assert_equal({keys[0] => 1, keys[1] => 3}, cache.get_multi(keys))
  end

  # def test_get_multi_binary
  #   binary_protocol_cache.set "#{key}_1", 1
  #   binary_protocol_cache.set "#{key}_3", 3
  #   assert_equal(
  #     {"test_get_multi_binary_3"=>3, "test_get_multi_binary_1"=>1},
  #     binary_protocol_cache.get_multi(["#{key}_1", "#{key}_2",  "#{key}_3"])
  #     )
  # end

  # def test_get_multi_binary_one_record_missing
  #   assert_equal({}, binary_protocol_cache.get_multi(["magic_key"]))
  # end

  # def test_get_multi_binary_one_record
  #   binary_protocol_cache.set("magic_key", 1)
  #   assert_equal({"magic_key" => 1}, binary_protocol_cache.get_multi(["magic_key"]))
  # end

  def test_get_multi_completely_missing
    assert_equal({}, cache.get_multi(["#{key}_1", "#{key}_2"]))
  end

  def test_get_multi_empty_string
    cache.set "#{key}_1", "", ttl: 0, raw: true
    assert_equal({"#{key}_1" => ""},
                  cache.get_multi(["#{key}_1"], raw: true))
  end

  def test_get_multi_coerces_string_type
    #assert cache.get_multi [nil] TODO

    assert_raise(TypeError) do
      cache.get_multi [1]
    end
  end

  def test_set_and_get_unmarshalled
    cache.set key, @value
    result = cache.get key, raw: true
    assert_equal @marshalled_value, result
  end

  def test_set_unmarshalled_and_get_unmarshalled
    cache.set key, @marshalled_value, raw: true
    result = cache.get key, raw: true
    assert_equal @marshalled_value, result
  end

  # def test_set_unmarshalled_error
  #   assert_raise(TypeError) do
  #     cache.set key, @value, raw: true
  #   end
  # end

  # def test_get_multi_unmarshalled
  #   cache.set "#{key}_1", "1", raw: true
  #   cache.set "#{key}_2", "2", raw: true
  #   assert_equal(
  #     {"#{key}_1" => "1", "#{key}_2" => "2"},
  #     cache.get_multi(["#{key}_1", "#{key}_2"], raw: true)
  #   )
  # end

  # def test_get_multi_mixed_marshalling
  #   cache.set "#{key}_1", 1
  #   cache.set "#{key}_2", "2", raw: true

  #   values = {"#{key}_1" => Marshal.dump(1), "#{key}_2" => "2"}
  #   assert_equal(values, cache.get_multi(["#{key}_1", "#{key}_2"], raw: true), "should return raw values from memcached, apart of the flags")

  #   values = {"#{key}_1" => 1, "#{key}_2" => "2"}
  #   assert_equal(values, cache.get_multi(["#{key}_1", "#{key}_2"]), "should use the flags to decode the right values")
  # end

  #  def test_random_distribution_is_statistically_random
  #    cache = Memcached.new(@servers, :distribution => :random)
  #    read_cache = Memcached.new(@servers.first)
  #    hits = 4
  #
  #    while hits == 4 do
  #      cache.flush
  #      20.times do |i|
  #        cache.set "#{key}#{i}", @value
  #      end
  #
  #      hits = 0
  #      20.times do |i|
  #        begin
  #          read_cache.get "#{key}#{i}"
  #          hits += 1
  #        rescue Memcached::NotFound
  #        end
  #      end
  #    end
  #
  #    assert_not_equal 4, hits
  #  end

  ###########     Gets     ###########
end