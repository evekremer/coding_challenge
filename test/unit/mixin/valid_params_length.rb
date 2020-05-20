# frozen_string_literal: true

require_relative '../../test_helper'

# Unit test for Memcached::Mixin module
# Test validate_parameters_min_length!
#   and validate_parameters_max_length! methods

class MixinValidateParamsLengthTest < BaseTest
  include Memcached::Mixin

  # Test validate_parameters_min_length!

  def test_validate_parameters_min_length_equal
    parameters = [key.to_s]
    min_length = parameters.length

    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_parameters_min_length_smaller
    parameters = [key.to_s]
    min_length = parameters.length - 1

    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_parameters_min_length_bigger
    parameters = [key.to_s]
    min_length = parameters.length + 1

    exception = assert_raise Memcached::ArgumentClientError do
      validate_parameters_min_length! parameters, min_length
    end
    assert_equal Memcached::TOO_FEW_ARGUMENTS_MSG, exception.message
  end

  def test_validate_parameters_min_length_empty
    parameters = []
    min_length = parameters.length

    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  def test_validate_min_length_coerces_array_type
    parameters = 1
    min_length = 1

    assert_nothing_raised do
      validate_parameters_min_length! parameters, min_length
    end
  end

  # Test validate_parameters_max_length! method

  def test_validate_parameters_max_length_equal
    parameters = [key.to_s]
    max_length = parameters.length

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_parameters_max_length_bigger
    parameters = [key.to_s]
    max_length = parameters.length + 1

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_parameters_max_length_smaller
    parameters = [key.to_s]
    max_length = parameters.length - 1

    exception = assert_raise Memcached::ArgumentClientError do
      validate_parameters_max_length! parameters, max_length
    end
    assert_equal Memcached::TOO_MANY_ARGUMENTS_MSG, exception.message
  end

  def test_validate_parameters_max_length_empty
    parameters = []
    max_length = parameters.length

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end

  def test_validate_max_length_coerces_array_type
    parameters = 1
    max_length = 1

    assert_nothing_raised do
      validate_parameters_max_length! parameters, max_length
    end
  end
end
