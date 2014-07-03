[![Build Status](https://travis-ci.org/pjanuario/zmq-service-suite-ruby.svg?branch=master)](https://travis-ci.org/pjanuario/zmq-service-suite-ruby)
[![Code Climate](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby.png)](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby)
[![Coverage](http://img.shields.io/codeclimate/coverage/github/pjanuario/zmq-service-suite-ruby.svg)](https://codeclimate.com/github/pjanuario/zmq-service-suite-ruby)
[![Dependency Status](https://gemnasium.com/pjanuario/zmq-service-suite-ruby.svg)](https://gemnasium.com/pjanuario/zmq-service-suite-ruby)

# ZMQ SOA Suite - Ruby Client &amp; Service

For now protocol description is under node js implementation and will be moved soon to a proper place.
https://github.com/pjanuario/zmq-service-suite


# ZSS Client

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
