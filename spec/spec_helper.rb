ENV['ZSS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

$:.push '.'

require 'rspec'
require 'pry'
require 'zss'

Dir['spec/support/**/*.rb'].each &method(:require)
