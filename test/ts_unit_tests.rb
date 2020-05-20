# frozen_string_literal: true

# Run all unit test except tests from 'unit/server' directory
Dir["#{__dir__}/unit/cache_handler/*.rb"].sort.each { |file| require file }
Dir["#{__dir__}/unit/commands/*.rb"].sort.each { |file| require file }
Dir["#{__dir__}/unit/lru_cache/*.rb"].sort.each { |file| require file }
Dir["#{__dir__}/unit/mixin/*.rb"].sort.each { |file| require file }
