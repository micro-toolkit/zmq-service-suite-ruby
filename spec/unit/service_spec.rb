require 'spec_helper'
require 'zss'
require 'zss/service'
require 'em-zeromq'

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

  def done
    subject.stop
    EM.stop
  end

  let(:context) { double('EM::ZeroMQ::Context').as_null_object }
  let(:socket) { double('EM::ZMQ::Socket').as_null_object }

  before :each do
    allow(EM::ZeroMQ::Context).to receive(:new) { context }
    allow(context).to receive(:socket) { socket }
    allow(SecureRandom).to receive(:uuid) { "uuid" }
    config.heartbeat = 60000
  end

  after :each do
    EM.stop if EM.reactor_running?
  end

  subject do
    described_class.new(:pong, config)
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

    context('on error') do

      it('raises RuntimeError on invalid context') do
        expect(EM::ZeroMQ::Context).to receive(:new) { nil }
        expect { subject.run }.to raise_exception(RuntimeError)
      end

      it('raises RuntimeError on invalid socket') do
        expect(context).to receive(:socket) { nil }
        expect { subject.run }.to raise_exception(RuntimeError)
      end

    end

    context('open ZMQ Socket') do

      it('with dealer type') do
        expect(context).to receive(:socket).with(ZMQ::DEALER) do
          done
          socket
        end
        subject.run
      end

      it('with identity set') do
        expect(socket).to receive(:identity=).with("pong#uuid") { done }
        subject.run
      end

      it('with linger set to 0') do
        expect(socket).to receive(:setsockopt).with(ZMQ::LINGER, 0) { done }
        subject.run
      end

      it('connect to socket address') do
        expect(socket).to receive(:connect).with(socket_address) { done }
        subject.run
      end

    end

    it('register service on broker') do
      expect(socket).to receive(:send_msg) do |*frames|
        message = ZSS::Message.parse(frames)
        expect(message.address.sid).to eq('SMI')
        expect(message.address.verb).to eq('UP')
        expect(message.payload).to eq('PONG')
        done
        true
      end

      subject.run
    end

    context('handling requests') do

      let(:address) { ZSS::Message::Address.new(sid: "PONG", verb: "PING") }

      let(:message) { ZSS::Message.new(address: address, payload: "PING") }

      let :message_parts do
        message.to_frames.map { |f| ZMQ::Message.new(f) }
      end

      it('returns payload and headers') do
        service = DummyService.new
        subject.add_route(service, :ping)

        EM.run do
          allow(socket).to receive(:on) do |event, &block|
            EM.add_timer { block.call *message_parts }
          end

          subject.run

          expect(socket).to receive(:send_msg) do |*frames|
            message = ZSS::Message.parse(frames)

            expect(message.type).to eq(ZSS::Message::Type::REP)
            expect(message.status).to eq(200)
            expect(message.headers).to eq({ "took" => "0s" })

            done

            true
          end
        end

      end

      context('on error') do

        it('returns 404 on invalid sid') do
          message.address.sid = "something"

          EM.run do
            allow(socket).to receive(:on) do |event, &block|
              EM.add_timer { block.call *message_parts }
            end

            subject.run

            expect(socket).to receive(:send_msg) do |*frames|
              message = ZSS::Message.parse(frames)

              expect(message.type).to eq(ZSS::Message::Type::REP)
              expect(message.status).to eq(404)

              done

              true
            end
          end

        end

        it('returns 404 on invalid verb') do

          message.address.verb = "something"

          EM.run do
            allow(socket).to receive(:on) do |event, &block|
              EM.add_timer { block.call *message_parts }
            end

            subject.run

            expect(socket).to receive(:send_msg) do |*frames|
              message = ZSS::Message.parse(frames)

              expect(message.type).to eq(ZSS::Message::Type::REP)
              expect(message.status).to eq(404)

              done

              true
            end
          end

        end

        it('returns 500 when an error occurred while handling request') do

          service = DummyService.new
          subject.add_route(service, "PING/FAIL", :ping_fail)
          message.address.verb = "PING/FAIL"

          EM.run do
            allow(socket).to receive(:on) do |event, &block|
              EM.add_timer { block.call *message_parts }
            end

            subject.run

            expect(socket).to receive(:send_msg) do |*frames|
              message = ZSS::Message.parse(frames)

              expect(message.type).to eq(ZSS::Message::Type::REP)
              expect(message.status).to eq(500)

              done

              true
            end
          end

        end

      end

    end

    it('sends heartbeat message') do
      config.heartbeat = 500
      subject = described_class.new(:pong, config)

      EM.run do

        subject.run

        expect(socket).to receive(:send_msg) do |*frames|
          message = ZSS::Message.parse(frames)

          expect(message.type).to eq(ZSS::Message::Type::REQ)
          expect(message.address.sid).to eq('SMI')
          expect(message.address.verb).to eq('HEARTBEAT')
          expect(message.payload).to eq('PONG')

          done

          true
        end
      end
    end

  end

  describe('#stop') do

    it('disconnects the socket') do
      EM.run do
        subject.run

        expect(socket).to receive(:disconnect) { done }

        subject.stop
      end
    end

    it('unregister service on broker') do
      EM.run do

        subject.run

        expect(socket).to receive(:send_msg) do |*frames|
          message = ZSS::Message.parse(frames)
          expect(message.address.sid).to eq('SMI')
          expect(message.address.verb).to eq('DOWN')
          expect(message.payload).to eq('PONG')
          done
          1
        end

        subject.stop
      end
    end

  end

end
