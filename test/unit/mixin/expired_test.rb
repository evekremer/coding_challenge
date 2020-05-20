# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test expired? method
class MixinExpiredTest < BaseTest
  include Memcached::Mixin

  #=> Receives only zero or Time class as valid arguments

  def test_expired_time
    time = Time.now - Memcached::SECONDS_PER_DAY # yesterday
    assert expired? time
  end

  def test_not_expired_time
    time = Time.now + Memcached::SECONDS_PER_DAY # tomorrow
    refute expired? time
  end

  def test_very_far_past_time
    time = Time.new(0, 1, 1) - (10**6000)
    assert expired? time
  end

  def test_very_far_future_time
    time = Time.new(2500, 1, 1) + (10**6000)
    refute expired? time
  end

  # Value zero means the item never expires
  def test_time_zero_integer
    time = 0
    refute expired? time
  end

  def test_coerces_integer_type_valid
    time = '0'
    refute expired? time
  end

  def test_time_integer_not_zero
    time = 4
    assert_raise ArgumentError do
      expired? time
    end
  end

  def test_coerces_integer_type_invalid_array
    time = [0]
    assert_raise TypeError do
      expired? time
    end
  end

  def test_coerces_integer_type_invalid_nil
    time = nil
    assert_raise TypeError do
      expired? time
    end
  end
end
