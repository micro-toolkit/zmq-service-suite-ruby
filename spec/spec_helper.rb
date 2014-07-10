ENV['ZSS_ENV'] ||= 'test'

if ENV['CODECLIMATE_REPO_TOKEN']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

$:.push '.'

require 'rspec'
require 'pry'
require 'zss'
require 'timeout'

Dir['spec/support/**/*.rb'].each &method(:require)

RSpec.configure do |c|
  c.around(:each) do |example|
    Timeout::timeout(2) {
      example.run
    }
  end
end
