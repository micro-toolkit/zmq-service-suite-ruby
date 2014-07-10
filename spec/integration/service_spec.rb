require 'spec_helper'
require 'spec_broker_helper'
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

  after :each do
    return unless @broker
    @broker.join
    @broker = nil
  end

  subject { described_class.new(:pong, config) }

  it('handles request') do
    @broker = run_broker_for_service(broker_backend, message) do |msg|
      expect(msg.payload).to eq("PONG")
      expect(msg.status).to eq(200)
      # this will allow stop service thread and
      # not to block broker thread
      Thread.new { subject.stop }
    end

    service = DummyService.new
    subject.add_route(service, :ping)
    subject.run
  end

  it('send heartbeat msg') do
    config.heartbeat = 200
    subject = described_class.new(:pong, config)
    @broker = run_broker_for_service(broker_backend) do |msg|
      expect(msg.address.sid).to eq("SMI")
      expect(msg.address.verb).to eq("HEARTBEAT")
      # this will allow stop service thread and
      # not to block broker thread
      Thread.new { subject.stop }
    end

    service = DummyService.new
    subject.add_route(service, :ping)
    subject.run
  end
end
