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

### Client errors

The client raises services errors using ZSS::Error class, with code, developer message and user message.

```ruby
require 'zss'

PongClient = ZSS::Client.new(:pong)

begin
  PongClient.ping("payload")
rescue ZSS::Error => error
  puts "Status code: #{error.code}"
  puts "User Message: #{error.user_message}"
  puts "Developer Message: #{error.developer_message}"
end

```

## ZSS Service

The ZSS Service is responsible for receiving ZSS Request and execute configured service handlers.

**The main components are:**
* ZSS::Service.new(:sid, config)

  This component responsible for receiving and routing ZSS requests.
  The first parameter is service identifier (sid), you can use either symbol or string.
  The configuration parameter will be used to pass heartbeat interval and broker backend address.

```ruby
  config = {
    backend: 'tcp://127.0.0.1:7776',  # default: tcp://127.0.0.1:7776
    heartbeat: 1000                   # ms, default: 1s
  }
  service = ZSS::Service.new(:pong, config)
```

* ZSS::Runner.run(:sid)

  This component is responsible to execute a ZSS::Service as daemon, when in background it redirects stdout to file and manages pid files. It uses [daemon gem](https://rubygems.org/gems/daemon).

      $ bin/pong run

  or in background, where pidfile and logs are under /log

      $ bin/pong start/stop

* ZSS::ServiceRegister

  This component is the glue entry point between Runner & Service.


**NOTE:** You can run services without using the runner and service register, they are just one way to run services, you can use your own. Using Runner and service registry all services are done on the same way and using shared infra.

### Creating a new service step by step

Let's create our first service sample, Ping-Pong, step by step.
Note: For your next services you will be able to use [Service Generation rake](#zss-service-generation-rake), but for now you learn what the rake does and why!

* Create you service logic class, adding a pong_service.rb under /lib folder.

```ruby
class PongService

  # it print's payload and headers on the console
  def ping(payload, headers)
    puts "Payload => #{payload}"
    puts "Headers => #{headers}"

    return "PONG"
  end

end

```
**NOTE:** Headers parameter is optional!

* Create the service registration, adding a service_register.rb under /lib folder.

```ruby
module ZSS
  class ServiceRegister

    def self.get_service
      config = Hashie::Mash.new(
        # this data should be received from a config file instead!
        backend: 'tcp://127.0.0.1:7776'
      )

      # create a service instance for sid :pong
      service = ZSS::Service.new(:pong, config)

      instance = PongService.new
      # register route ping for the service
      service.add_route(instance, :ping)

      service
    end
  end
end

```

* Hook your files by creating start.rb under /lib folder.

```ruby
require 'zss/service'

require_relative 'service_register'
require_relative 'pong_service'
```

* Register LoggerFacade plugin/s

The ZSS library uses the [LoggerFacade](https://github.com/pjanuario/logger-facade-ruby) library to abstract logging info, so you should hook your plugins on start.rb.


```ruby
# log level should be retrieved from a configuration file
plugin = LoggerFacade::Plugins::Console.new({ level: :debug })
LoggerFacade::Manager.use(plugin)
```

* Create a binary file to run the service as daemon, such as bin/pong

```ruby
#!/usr/bin/env ruby
require 'rubygems' unless defined?(Gem)

require 'bundler/setup'
Bundler.require

$env     = ENV['ZSS_ENV'] || 'development'

require 'zss/runner'
require_relative '../lib/start'

# Runner receives the identifier used for pid and log filename
ZSS::Runner.run(:pong)
```

**NOTES:**
* ZSS_ENV: is used to identify the running environment


You running service example [here](https://github.com/pjanuario/zss-service-sample)

### Returning errors

Every exception that is raised by the service is shield and result on a response with status code 500 with default user and developer messages.

The available errors dictionary is defined in [error.json](https://github.com/pjanuario/zmq-service-suite-ruby/blob/master/lib/zss/errors.json).

**Raising different errors**

```ruby
raise Error[500]
# or
raise Error.new
# or
raise Error.new(500)
# or with developer message override
raise Error.new(500, "this message should helpfull for developer!")
```
When relevant errors should be raised be with developer messages!

**New Error Types**

New error types should be added to [error.json](https://github.com/pjanuario/zmq-service-suite-ruby/blob/master/lib/zss/errors.json) using pull request.


### ZSS Service Generation Rake

[**#TODO**](https://github.com/pjanuario/zmq-service-suite-ruby/issues/11)

rake zss:service sid (--airbrake)

It generates the service skeleton, adding several files into root directory:
* sid - binary file named with sid
* start.rb with console plugin attached (--airbrake will add Airbrake plugin also)
* sid_service.rb
* service_register.rb
* config/application.yml
* travis.yml
* .rvmrc.sample
* .rvmrc
* .rspec
* Gemfile
* .gitignore

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
