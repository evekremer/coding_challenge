# frozen_string_literal: true

# Run all server unit test from: 'unit/server' directory
Dir["#{__dir__}/unit/server/*.rb"].sort.each { |file| require file }
