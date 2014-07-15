require 'spec_helper'
require 'spec_broker_helper'
require 'em-zeromq'
require 'zss/service'

describe ZSS::Service do
  include BrokerHelper

  class DummyService
    def ping payload, headers
      headers[:took] = "0s"
      return "PONG"
    end
  end

  let(:broker_backend) { "ipc://socket_test" }

  let(:config) do
    Hashie::Mash.new(
      backend: broker_backend,
      heartbeat:  2000
    )
  end

  let(:address) { ZSS::Message::Address.new(sid: "pong", verb: "ping") }

  let(:message) { ZSS::Message.new(address: address, payload: "PING") }

  subject { described_class.new(:pong, config) }

  it('handles request') do
    EM.run do
      run_broker_for_service(broker_backend, message) do |msg|
        expect(msg.payload).to eq("PONG")
        expect(msg.status).to eq(200)
        expect(msg.headers).to eq({ "took" => "0s" })
        subject.stop
        EM.stop
      end

      service = DummyService.new
      subject.add_route(service, :ping)
      subject.run
    end

  end

end
