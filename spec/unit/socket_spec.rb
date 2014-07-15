require 'spec_helper'
require 'zss/socket'
require 'ffi-rzmq'

describe ZSS::Socket do

  let(:socket_address) { "ipc://socket_spec" }

  let :config do
    Hashie::Mash.new(
      socket_address: socket_address,
      identity: 'socket-identity',
      timeout: 300
    )
  end

  let(:address) { ZSS::Message::Address.new(sid: "service", verb: "verb") }

  let(:message) { ZSS::Message.new(address: address, payload: "PING") }

  let(:context) { double('ZMQ::Context').as_null_object }

  let(:socket) { double('ZMQ::Socket').as_null_object }

  before(:each) do
    allow(SecureRandom).to receive(:uuid) { "uuid" }
  end

  subject { ZSS::Socket.new(config) }

  describe("#call") do

    context('open ZMQ Socket') do

      before :each do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { socket }
        allow(socket).to receive(:send_string) { -1 }
      end

      it('with dealer type') do
        expect(context).to receive(:socket).with(ZMQ::DEALER)
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('with identity set') do
        expect(socket).to receive(:identity=).with("socket-identity#uuid")
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('with linger set to 0') do
        expect(socket).to receive(:setsockopt).with(ZMQ::LINGER, 0)
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('connect to socket address') do
        expect(socket).to receive(:connect).with(socket_address)
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

    end

    context('on error') do

      it('raises Socket::Error on invalid request') do
        expect { subject.call(nil) }.
          to raise_exception(ZSS::Socket::Error)
      end

      it('raises ::Timeout::Error on subject timeout') do
        expect { subject.call(message) }.
          to raise_exception(ZSS::Socket::TimeoutError, "call timeout after 0.3s")
      end

      it('raises ::Timeout::Error on call timeout') do
        expect { subject.call(message, 200) }.
          to raise_exception(ZSS::Socket::TimeoutError, "call timeout after 0.2s")
      end

      it('raises Socket::Error on invalid context') do
        allow(ZMQ::Context).to receive(:create) { nil }
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('raises Socket::Error on invalid socket') do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { nil }
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('raises Socket::Error on invalid send send_string') do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { socket }
        allow(socket).to receive(:send_string) { -1 }
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

    end

    context('clean up resources') do

      it('terminates context') do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { nil }
        expect(context).to receive(:terminate)
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

      it('closes socket') do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { socket }
        allow(socket).to receive(:send_string) { -1 }
        expect(socket).to receive(:close)
        expect { subject.call(message) }.to raise_exception(ZSS::Socket::Error)
      end

    end

    describe('on success') do

      before :each do
        allow(ZMQ::Context).to receive(:create) { context }
        allow(context).to receive(:socket) { socket }
      end

      it('returns a result') do
        frames = []
        allow(socket).to receive(:send_string) do |frame|
          frames << frame
          0 # return success result code
        end
        allow(socket).to receive(:recv_strings) do |buffer|
          frames.each { |f| buffer << f }
          0 # return success result code
        end

        result = subject.call(message)
        expect(result.payload).to eq(message.payload)
      end

    end

  end

end
