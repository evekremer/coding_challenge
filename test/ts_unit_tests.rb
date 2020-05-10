# Run all unit test except tests from 'unit/server' directory
Dir["#{__dir__}/unit/cache_handler/*.rb"].each {|file| require file }
Dir["#{__dir__}/unit/commands/*.rb"].each {|file| require file }
Dir["#{__dir__}/unit/lru_cache/*.rb"].each {|file| require file }
Dir["#{__dir__}/unit/*.rb"].each {|file| require file }