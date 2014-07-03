require 'spec_helper'
require 'zss/client'

describe ZSS::Client do

  describe('#ctor') do

    it('returns a client with default config') do
      subject = described_class.new(:pong)
      expect(subject.frontend).to eq(ZSS::Configuration.default.frontend)
      expect(subject.identity).to eq("client")
      expect(subject.timeout).to eq(1000)
    end

    it('returns a client with config') do
      config = Hashie::Mash.new(
        frontend: "socket",
        identity: "identity",
        timeout:  2000
      )
      subject = described_class.new(:pong, config)
      expect(subject.frontend).to eq("socket")
      expect(subject.identity).to eq("identity")
      expect(subject.timeout).to eq(2000)
    end

    it('returns a client with sid') do
      subject = described_class.new(:pong)
      expect(subject.sid).to eq("PONG")
    end

  end

  describe("#call") do

    subject do
      described_class.new(:pong)
    end

    it('creates a socket with configs') do
      socket = double('socket').as_null_object
      allow(ZSS::Socket).to receive(:new) { socket }
      allow(socket).to receive(:call) do |msg|
        msg.status = 200
        msg
      end
      expect(ZSS::Socket).to receive(:new)
        .with(
          Hashie::Mash.new(
            socket_address: ZSS::Configuration.default.frontend,
            identity: "client",
            timeout: 1000
          )
        )
      subject.call(:ping)
    end

    context('on success') do

      it('calls pong service') do
        socket = double('socket')
        allow(ZSS::Socket).to receive(:new) { socket }
        expect(socket).to receive(:call) do |msg|
          expect(msg).to be_truthy
          expect(msg.address.sid).to eq("PONG")
          expect(msg.address.verb).to eq("PING")
          expect(msg.payload).to eq("ping")
          msg.status = 200
          msg
        end
        result = subject.call(:ping, "ping")
      end

      it('calls pong service with headers') do
        socket = double('socket')
        allow(ZSS::Socket).to receive(:new) { socket }
        expect(socket).to receive(:call) do |msg|
          expect(msg).to be_truthy
          expect(msg.headers[:something]).to eq("something")
          msg.status = 200
          msg
        end
        result = subject.call(:ping, "ping", headers: { something: "something" })
      end

      it('returns service message from pong service') do
        socket = double('socket')
        allow(ZSS::Socket).to receive(:new) { socket }
        allow(socket).to receive(:call) do |msg|
          msg.payload = "pong"
          msg.status = 200
          msg
        end
        result = subject.call(:ping, "ping")
        expect(result).to eq("pong")
      end

      context('with implicit method implementation') do

        it('returns service message from pong service') do
          socket = double('socket')
          allow(ZSS::Socket).to receive(:new) { socket }
          allow(socket).to receive(:call) do |msg|
            msg.payload = "pong"
            msg.status = 200
            msg
          end
          result = subject.ping("ping")
          expect(result).to eq("pong")
        end

        it('calls pong service with special verb') do
          socket = double('socket')
          allow(ZSS::Socket).to receive(:new) { socket }
          expect(socket).to receive(:call) do |msg|
            expect(msg).to be_truthy
            expect(msg.address.sid).to eq("PONG")
            expect(msg.address.verb).to eq("PONG/PING")

            msg.payload = "pong"
            msg.status = 200
            msg
          end
          result = subject.pong_ping("ping")
          expect(result).to eq("pong")
        end

      end

    end

    context('on error') do

      it('raise service error') do
        socket = double('socket')
        allow(ZSS::Socket).to receive(:new) { socket }
        allow(socket).to receive(:call) do |msg|
          msg.payload = Hashie::Mash.new(
            userMessage: "user info",
            developerMessage: "dev info"
          )
          msg.status = 500
          msg
        end

        expect { subject.call(:ping, "ping") }.to raise_exception(ZSS::Error) do |error|
            expect(error.code).to eq(500)
        end
      end

    end

  end

end
