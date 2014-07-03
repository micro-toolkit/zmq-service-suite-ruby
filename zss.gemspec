lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/zss/version'

Gem::Specification.new do |spec|
  spec.name          = 'zss'
  spec.version       = ZSS::VERSION
  spec.authors       = ["Pedro Januário"]
  spec.email         = ["prnjanuario@gmail.com"]
  spec.description   = %q{ZeroMQ SOA Suite}
  spec.summary       = %q{ZeroMQ SOA Suite}
  spec.homepage      = "https://github.com/pjanuario/zmq-service-suite-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'simplecov'

  spec.add_dependency 'msgpack'
  spec.add_dependency 'ffi-rzmq'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'hashie'
end
