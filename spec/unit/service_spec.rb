require 'spec_helper'
require 'zss/service'
require 'zss/socket'

describe ZSS::Service do

  let(:socket_address) { "ipc://socket_spec" }

  let :config do
    Hashie::Mash.new(
      backend: socket_address,
      heartbeat: 60000
    )
  end

  class DummyService
    def ping payload, headers
      headers[:took] = "0s"
      return "PONG"
    end

    def ping_fail payload, headers
      fail 'should raise exception'
    end
  end

  before(:each) do
    allow(SecureRandom).to receive(:uuid) { "uuid" }
  end

  describe('#ctor') do

    it('returns a service with default config') do
      subject = described_class.new(:pong)
      expect(subject.sid).to eq("PONG")
      expect(subject.backend).to eq(ZSS::Configuration.default.backend)
      expect(subject.heartbeat).to eq(1000)
    end

    it('returns a service with config') do
      config = Hashie::Mash.new(
        backend: "socket",
        heartbeat:  2000
      )
      subject = described_class.new(:pong, config)
      expect(subject.sid).to eq("PONG")
      expect(subject.backend).to eq("socket")
      expect(subject.heartbeat).to eq(2000)
    end

    it('raises an error on invalid sid') do

      expect do
        described_class.new(nil, nil)
      end.to raise_exception(ZSS::Error) do |error|
          expect(error.code).to eq(500)
      end

    end

  end

  describe('#run') do

    let(:socket) { double('Socket').as_null_object }
    let(:zmq_socket) { double('ZMQ::Socket').as_null_object }

    before :each do
      @last = nil
      allow(ZSS::Socket).to receive(:new) { socket }
      allow(socket).to receive(:connect) { zmq_socket }
      # store last message to retrieve on receive
      allow(socket).to receive(:send) { |m| @last = m }
      # return last message first time and stop after
      allow(socket).to receive(:receive) do

        if msg = @last
          @last = nil
          msg.status = 200
          msg.type = ZSS::Message::Type::REP
        else
          subject.stop
        end

        msg
      end
    end

    subject do
      described_class.new(:pong, config)
    end

    it('connects a socket') do
      expect(socket).to receive(:connect)
      subject.run
    end

    it('register service on broker') do
      expect(socket).to receive(:send) do |message|
        @last = message
        expect(message.address.sid).to eq('SMI')
        expect(message.address.verb).to eq('UP')
        expect(message.payload).to eq('PONG')
      end
      subject.run
    end

    context('handling requests') do

      let(:address) { ZSS::Message::Address.new(sid: "PONG", verb: "PING") }

      let(:message) { ZSS::Message.new(address: address, payload: "PING") }

      before :each do
        allow(ZSS::Socket).to receive(:new) { socket }
        allow(socket).to receive(:connect) { zmq_socket }
        allow(socket).to receive(:send)
        message.rid = "req-uuid"
      end

      it('returns payload and headers') do

        # reply to up, receive request and reply to down
        allow(socket).to receive(:receive) do
          if msg = @last
            @last = nil
            msg.status = 200
            msg.type = ZSS::Message::Type::REP
          elsif !@request_send
            message.address.verb = "PING"
            msg = message
          end

          msg
        end
        # receive up, reply
        expect(socket).to receive(:send).exactly(2).times do |msg|
          @last = msg
          if msg.rid == message.rid
            expect(msg.status).to eq(200)
            expect(msg.payload).to eq("PONG")
            expect(msg.headers).to eq({ took: "0s" })
            subject.stop
          end
        end

        service = DummyService.new
        subject.add_route(service, :ping)

        subject.run
      end

      context('on error') do

        it('returns 404 on invalid sid') do
          # reply to up, receive request and reply to down
          allow(socket).to receive(:receive) do
            if msg = @last
              @last = nil
              msg.status = 200
              msg.type = ZSS::Message::Type::REP
            elsif !@request_send
              message.address.sid = "something"
              msg = message
            end

            msg
          end
          # receive up, reply
          expect(socket).to receive(:send).exactly(2).times do |msg|
            @last = msg
            if msg.rid == message.rid
              expect(msg.status).to eq(404)
              subject.stop
            end
          end

          subject.run
        end

        it('returns 404 on invalid verb') do
          # reply to up, receive request and reply to down
          allow(socket).to receive(:receive) do
            if msg = @last
              @last = nil
              msg.status = 200
              msg.type = ZSS::Message::Type::REP
            elsif !@request_send
              message.address.verb = "something"
              msg = message
            end

            msg
          end
          # receive up, reply
          expect(socket).to receive(:send).exactly(2).times do |msg|
            @last = msg
            if msg.rid == message.rid
              expect(msg.status).to eq(404)
              subject.stop
            end
          end

          subject.run
        end

        it('returns 500 when an error occurred while handling request') do
          # reply to up, receive request and reply to down
          allow(socket).to receive(:receive) do
            if msg = @last
              @last = nil
              msg.status = 200
              msg.type = ZSS::Message::Type::REP
            elsif !@request_send
              message.address.verb = "PING/FAIL"
              msg = message
            end

            msg
          end
          # receive up, reply
          expect(socket).to receive(:send).exactly(2).times do |msg|
            @last = msg
            if msg.rid == message.rid
              expect(msg.status).to eq(500)
              subject.stop
            end
          end

          service = DummyService.new
          subject.add_route(service, "PING/FAIL", :ping_fail)

          subject.run
        end

      end

    end

  end

  describe('#stop') do

    let(:socket) { double('Socket').as_null_object }
    let(:zmq_socket) { double('ZMQ::Socket').as_null_object }

    subject do
      described_class.new(:pong, config)
    end

    before :each do
      allow(ZSS::Socket).to receive(:new) { socket }
      allow(socket).to receive(:connect) { zmq_socket }
      allow(socket).to receive(:send)
      @runner = Thread.new do
        subject.run
      end
      # force previous thread to run
      sleep(0.1)
    end

    after :each do
      return unless @runner
      @runner.join(0.5)
      @runner.terminate
      @runner = nil
    end

    it('disconnects the socket') do
      expect(socket).to receive(:disconnect)
      subject.stop
    end

    it('unregister service on broker') do
      expect(socket).to receive(:send) do |message|
        expect(message.address.sid).to eq('SMI')
        expect(message.address.verb).to eq('DOWN')
        expect(message.payload).to eq('PONG')
        message
      end
      subject.stop
    end

  end

end
