lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/zss/version'

Gem::Specification.new do |spec|
  spec.name          = 'zss'
  spec.version       = ZSS::VERSION
  spec.authors       = ["Pedro Januário"]
  spec.email         = ["prnjanuario@gmail.com"]
  spec.description   = %q{ZeroMQ SOA Suite}
  spec.summary       = %q{This project is a ruby client&service implementation for ZMQ Service Suite,
                          check http://pjanuario.github.io/zmq-service-suite-specs/ for more info.}
  spec.homepage      = "https://github.com/pjanuario/zmq-service-suite-ruby"
  spec.metadata      = {
    "source_code" => "https://github.com/pjanuario/zmq-service-suite-ruby",
    "issue_tracker" => "https://github.com/pjanuario/zmq-service-suite-ruby/issues"
  }
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.3'
  spec.add_development_dependency 'bump', '~> 0.5'

  spec.add_dependency 'msgpack', '~> 1.1.0'
  spec.add_dependency 'ffi-rzmq', '~> 2.0'
  spec.add_dependency 'activesupport', '>= 4.2'
  spec.add_dependency 'hashie', '~> 3.2'
  spec.add_dependency 'daemons', '~> 1.1'
  spec.add_dependency 'em-zeromq', '~> 0.5'
  spec.add_dependency 'party_foul'
end
