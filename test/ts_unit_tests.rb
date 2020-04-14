# Run all unit test
raise "ruby ./test/unit/lru_test.rb failed" unless system("ruby ./test/unit/lru_test.rb")
require_relative './unit/add_replace_test'
require_relative './unit/cas_test'
require_relative './unit/concurrency_test'
require_relative './unit/error_states_test'
require_relative './unit/get_gets_test'
require_relative './unit/pre_append_test'
require_relative './unit/set_test'
require_relative './unit/purge_expired_test'