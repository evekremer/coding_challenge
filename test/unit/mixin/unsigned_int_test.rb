# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test unsigned_i? method
class MixinUnsignedIntTest < BaseTest
  include Memcached::Mixin

  def test_is_ui_positive
    assert unsigned_i? '10'
  end

  def test_is_ui_negative
    refute unsigned_i? '-10'
  end

  def test_is_ui_signed_positive
    refute unsigned_i? '+10'
  end

  def test_is_ui_zero
    assert unsigned_i? '0'
  end

  def test_is_ui_end_neg_sign
    refute unsigned_i? '10-'
  end

  def test_is_ui_end_pos_sign
    refute unsigned_i? '10+'
  end

  def test_is_ui_without_digits
    refute unsigned_i? 'test'
  end

  def test_is_ui_with_digits
    refute unsigned_i? '123abc'
  end

  def test_is_ui_float
    refute unsigned_i? 12.50
  end

  def test_is_ui_coerces_string_type_integer
    assert unsigned_i? 300
  end

  def test_is_ui_coerces_string_type_time
    refute unsigned_i? Time.new
  end

  def test_is_ui_coerces_string_type_nil
    refute unsigned_i? nil
  end

  # Test optional num_bits

  def test_is_ui_limit_pos
    assert unsigned_i? 5678, 10_000
  end

  def test_is_ui_limit_zero
    assert unsigned_i? 0, 10_000
  end

  def test_is_ui_limit_out_of_range
    refute unsigned_i? 2**32 + 1, 10_000
  end

  def test_is_ui_limit_data_not_unsigned
    refute unsigned_i? -9023, 10
  end

  def test_is_ui_limit_coerces_integer_type_data
    assert unsigned_i? '1000', 1001
  end

  def test_is_ui_limit_coerces_integer_type_limit
    assert unsigned_i? 1000, '1001'
  end

  def test_is_ui_limit_coerces_integer_type_array
    refute unsigned_i? [], 40
  end

  def test_is_ui_limit_coerces_integer_type_nil_data
    refute unsigned_i? nil, 40
  end

  def test_is_ui_limit_coerces_integer_type_hash_limit
    assert_raises TypeError do
      unsigned_i? 60, {}
    end
  end

  def test_is_ui_limit_negative
    refute unsigned_i? 9023, -2
  end

  def test_is_ui_with_limit_zero
    refute unsigned_i? 9023, 0
  end
end
