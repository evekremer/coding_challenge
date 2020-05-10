# Run all server unit test from: 'unit/server' directory
Dir["#{__dir__}/unit/server/*.rb"].each {|file| require file }
