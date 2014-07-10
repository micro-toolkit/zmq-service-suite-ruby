require 'spec_helper'
require 'spec_broker_helper'
require 'zss/socket'

describe ZSS::Socket do
  include BrokerHelper

  let(:broker_frontend) { "ipc://socket_test" }

  let(:config) { Hashie::Mash.new(socket_address: broker_frontend) }

  let(:address) { ZSS::Message::Address.new(sid: "service", verb: "verb") }

  let(:message) { ZSS::Message.new(address: address, payload: "PING") }

  after :each do
    return unless @broker
    @broker.join
    @broker = nil
  end

  describe("#call") do

    subject { ZSS::Socket.new(config) }

    it('returns service response') do
      @broker = run_broker_for_client(broker_frontend) do |msg|
        msg.status = 200
        msg.payload = "PONG"
      end

      result = subject.call(message)
      expect(result).to be_truthy
      expect(result.payload).to eq("PONG")
      expect(result.status).to eq(200)
    end

  end

end
