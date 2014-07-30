[![Build Status](https://travis-ci.org/pjanuario/zmq-service-suite-ruby.svg?branch=master)](https://travis-ci.org/pjanuario/zmq-service-suite-ruby)
[![Code Climate](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby.png)](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby)
[![Coverage](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby/coverage.png)](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby)
[![Dependency Status](https://gemnasium.com/pjanuario/zmq-service-suite-ruby.svg)](https://gemnasium.com/pjanuario/zmq-service-suite-ruby)
[![Gem Version](https://badge.fury.io/rb/zss.svg)](http://badge.fury.io/rb/zss)

# ZMQ SOA Suite - Ruby Client &amp; Service

This project is a ruby client&service implementation for [ZMQ Service Suite](http://pjanuario.github.io/zmq-service-suite-specs/).

## Installation

Add this line to your application's Gemfile:

    gem 'zss'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zss

**NOTE:**

You need to have [0MQ installed](http://zeromq.org/area:download).

If you use MacOS just do

    $ brew install zeromq


## ZSS Client

```ruby
require 'zss'

# default Client config
config = {
  frontend: 'tcp://127.0.0.1:5560',
  identity: 'client',
  timeout: 1000 # in ms
}

# it uses default configs
PongClient = ZSS::Client.new(:pong)

# it uses configs
# who can override just a single property
PongClient = ZSS::Client.new(:pong, config)

# call Pong service on verb PING with "payload"
PongClient.ping("payload")
#or
PongClient.call("ping", "payload")

# call Pong service on verb PING with "payload" and headers
PongClient.ping("payload", headers: { something: "data" })
# or
PongClient.call("ping", "payload", headers: { something: "data" })

# call Pong service on verb PING with "payload"
PongClient.ping_pong("payload")
# or
PongClient.call("ping/pong", "payload")

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Bump versioning

We use [bump gem](https://github.com/gregorym/bump) to control gem versioning.

Bump Patch version

    $ bump patch

Bump Minor version

    $ bump minor

Bump Major version

    $ bump major

## Running Specs

    $ rspec

## Coverage Report

    $ open ./coverage/index.html
