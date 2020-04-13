# All unit test, except from 'lru_test' which needs to be run from empty cache
require_relative './unit/add_replace_test'
require_relative './unit/cas_test'
require_relative './unit/concurrency_test'
require_relative './unit/error_states_test'
require_relative './unit/get_gets_test'
require_relative './unit/pre_append_test'
require_relative './unit/set_test'