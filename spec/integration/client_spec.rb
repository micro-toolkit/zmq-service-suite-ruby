require 'spec_helper'
require 'spec_broker_helper'
require 'zss/client'

describe ZSS::Client do
  include BrokerHelper

  let(:broker_frontend) { "ipc://socket_test" }

  let(:config) do
    Hashie::Mash.new(
      frontend: broker_frontend,
      identity: "spec_client",
      timeout:  500
    )
  end

  after :each do
    return unless @broker
    @broker.join
    @broker = nil
  end

  subject do
    described_class.new(:pong, config)
  end

  it('returns service response') do
    @broker = run_broker_for_client(broker_frontend) do |msg|
      expect(msg.payload).to eq("ping")
      msg.status = 200
      msg.payload = "PONG"
    end

    result = subject.ping("ping", headers: { something: "data" })
    expect(result).to eq("PONG")
  end

end
