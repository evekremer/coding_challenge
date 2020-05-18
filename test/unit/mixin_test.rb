
require_relative "../test_helper"

# Unit test for Memcached::Mixin module
class MixinTest < BaseTest
  include Memcached::Mixin

  # Test is_expired? method

  #=> Receives only zero or Time class as valid arguments

  def test_expired_time
    time = Time.now - Memcached::SECONDS_PER_DAY # yesterday
    assert is_expired? time
  end

  def test_not_expired_time
    time = Time.now + Memcached::SECONDS_PER_DAY # tomorrow
    refute is_expired? time
  end

  def test_very_far_past_time
    time = Time.new(0,1,1) - (10 ** 6000)
    assert is_expired? time
  end

  def test_very_far_future_time
    time = Time.new(2500,1,1) + (10 ** 6000)
    refute is_expired? time
  end

  # Value zero means the item never expires
  def test_time_zero_integer
    time = 0
    refute is_expired? time
  end

  def test_coerces_integer_type_valid
    time = '0'
    refute is_expired? time
  end

  def test_time_integer_not_zero
    time = 4
    assert_raise ArgumentError do
      is_expired? time
    end
  end

  def test_coerces_integer_type_invalid_array
    time = [0]
    assert_raise TypeError do
      is_expired? time
    end
  end

  def test_coerces_integer_type_invalid_nil
    time = nil
    assert_raise TypeError do
      is_expired? time
    end
  end

  # Test contains_control_characters? method

  def test_control_char_empty_string
    refute contains_control_characters? ''
  end
  
  def test_control_char_tab
    assert contains_control_characters? "\tdata"
  end

  def test_control_char_cmd_ending
    assert contains_control_characters? "key\r\n"
  end

  def test_double_backslash
    refute contains_control_characters? "\\t"
  end

  def test_backslash_t
    refute contains_control_characters? '\t'
  end

  def test_null_char_hexa
    assert contains_control_characters? "null_char_hexadecimal\x00"
  end

  def test_null_char_oct
    assert contains_control_characters? "null_char_octal\000"
  end

  def test_carriage_return
    assert contains_control_characters? "!'_\r.\'n=#_"
  end

  def test_new_line_decimal
    # Decimal ASCII 10
    assert contains_control_characters? "start\10end"
  end

  def test_new_line_hexa
    # Hexadecimal ASCII 0x0a
    assert contains_control_characters? "start\x0aend"
  end

  def test_new_line_octal
    # Octal ASCII 012
    assert contains_control_characters? "start\012end"
  end

  def test_new_line_incorrect_syntax
    refute contains_control_characters? "data_\X0a_data"
  end

  def test_new_line_upercase_incorrect_syntax
    refute contains_control_characters? "start\R\Nend"
  end

  def test_coerces_string_type_integer
    refute contains_control_characters? 300
  end

  def test_coerces_string_type_array
    refute contains_control_characters? Array.new
  end

  def test_coerces_string_type_nil
    refute contains_control_characters? nil
  end

  # Test is_i? method

  def test_is_i_pos
    assert is_i? '10'
  end

  def test_is_i_signed_neg
    assert is_i? '-10'
  end

  def test_is_i_signed_pos
    assert is_i? '+10'
  end

  def test_is_i_zero
    assert is_i? '0'
  end

  def test_is_i_signed_neg_end
    refute is_i? '10-'
  end

  def test_is_i_signed_pos_end
    refute is_i? '10+'
  end

  def test_is_i_without_digits
    refute is_i? 'test'
  end

  def test_is_i_with_digits
    refute is_i? 'abc123'
  end

  def test_is_i_string_float
    refute is_i? '12.50'
  end
  
  def test_is_i_coerces_string_type_integer
    assert is_i? 300
  end

  def test_is_i_coerces_string_type_time
    refute is_i? Time.new
  end

  def test_is_i_coerces_string_type_nil
    refute is_i? nil
  end

  # Test is_unsigned_i? method

  def test_is_ui_positive
    assert is_unsigned_i? '10'
  end

  def test_is_ui_negative
    refute is_unsigned_i? '-10'
  end

  def test_is_ui_signed_positive
    refute is_unsigned_i? '+10'
  end

  def test_is_ui_zero
    assert is_unsigned_i? '0'
  end

  def test_is_ui_end_neg_sign
    refute is_unsigned_i? '10-'
  end

  def test_is_ui_end_pos_sign
    refute is_unsigned_i? '10+'
  end

  def test_is_ui_without_digits
    refute is_unsigned_i? 'test'
  end

  def test_is_ui_with_digits
    refute is_unsigned_i? '123abc'
  end

  def test_is_ui_float
    refute is_unsigned_i? 12.50
  end
  
  def test_is_ui_coerces_string_type_integer
    assert is_unsigned_i? 300
  end

  def test_is_ui_coerces_string_type_time
    refute is_unsigned_i? Time.new
  end

  def test_is_ui_coerces_string_type_nil
    refute is_unsigned_i? nil
  end

  # Test optional num_bits

  def test_is_ui_limit_pos
    assert is_unsigned_i? 5678, 10000
  end

  def test_is_ui_limit_zero
    assert is_unsigned_i? 0, 10000
  end

  def test_is_ui_limit_out_of_range
    refute is_unsigned_i? 2 ** 32 + 1, 10000
  end

  def test_is_ui_limit_data_not_unsigned
    refute is_unsigned_i? -9023, 10
  end

  def test_is_ui_limit_coerces_integer_type_data
    assert is_unsigned_i? '1000', 1001
  end

  def test_is_ui_limit_coerces_integer_type_limit
    assert is_unsigned_i? 1000, '1001'
  end

  def test_is_ui_limit_coerces_integer_type_array
    refute is_unsigned_i? Array.new, 40
  end

  def test_is_ui_limit_coerces_integer_type_nil_data
    refute is_unsigned_i? nil, 40
  end

  def test_is_ui_limit_coerces_integer_type_hash_limit
    assert_raises TypeError do  
      is_unsigned_i? 60, Hash.new
    end
  end

  def test_is_ui_limit_negative
    refute is_unsigned_i? 9023, -2
  end

  def test_is_ui_with_limit_zero
    refute is_unsigned_i? 9023, 0
  end
end