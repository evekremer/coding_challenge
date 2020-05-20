# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test i? method
class MixinIntTest < BaseTest
  include Memcached::Mixin

  def test_is_i_pos
    assert i? '10'
  end

  def test_is_i_signed_neg
    assert i? '-10'
  end

  def test_is_i_signed_pos
    assert i? '+10'
  end

  def test_is_i_zero
    assert i? '0'
  end

  def test_is_i_signed_neg_end
    refute i? '10-'
  end

  def test_is_i_signed_pos_end
    refute i? '10+'
  end

  def test_is_i_without_digits
    refute i? 'test'
  end

  def test_is_i_with_digits
    refute i? 'abc123'
  end

  def test_is_i_string_float
    refute i? '12.50'
  end

  def test_is_i_coerces_string_type_integer
    assert i? 300
  end

  def test_is_i_coerces_string_type_time
    refute i? Time.new
  end

  def test_is_i_coerces_string_type_nil
    refute i? nil
  end
end
