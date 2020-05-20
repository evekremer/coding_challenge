# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
#   Test contains_control_characters? method
class MixinControlCharsTest < BaseTest
  include Memcached::Mixin

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
    refute contains_control_characters? '\\t'
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
    refute contains_control_characters? []
  end

  def test_coerces_string_type_nil
    refute contains_control_characters? nil
  end
end
