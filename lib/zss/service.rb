require 'em-zeromq'
require_relative 'router'
require_relative 'message/smi'

module ZSS
  class Service

    attr_reader :sid, :heartbeat, :backend, :identity

    def initialize(sid, config = {})

      fail Error[500] if sid.blank?

      @sid = sid.to_s.upcase
      @heartbeat = config.try(:heartbeat) || 1000
      @backend   = config.try(:backend) || Configuration.default.backend
      @router = ZSS::Router.new
      @identity = "#{sid}##{SecureRandom.uuid}"
    end

    def run
      Thread.abort_on_exception = true

      context = EM::ZeroMQ::Context.new(1)
      fail RuntimeError, 'failed to create create_context' unless context

      # puts "Starting SID: '#{sid}' ID: '#{identity}'"
      # puts "Env: #{ZSS::Environment.env}"
      # puts "Broker: #{backend}"

      EM.run do
        # handle interrupts
        Signal.trap("INT") { stop }
        Signal.trap("TERM") { stop }

        connect_socket context

        start_heartbeat_worker

        # send up message
        send Message::SMI.up(sid)
      end
    end

    def add_route(context, route, handler = nil)
      router.add(context, route, handler)
    end

    def stop
      timer.cancel if timer

      # puts "Stoping SID: '#{sid}' ID: '#{socket.identity}'"
      EM.add_timer do
        send Message::SMI.down(sid)
        socket.disconnect backend
        EM::stop
      end
    end

    private

    attr_accessor :socket, :router, :timer

    def connect_socket(context)

      @socket = context.socket ZMQ::DEALER
      fail RuntimeError, 'failed to create socket' unless socket

      socket.identity = identity
      socket.setsockopt(ZMQ::LINGER, 0)
      socket.on(:message, &method(:handle_frames))

      socket.connect(backend)
    end

    def start_heartbeat_worker
      @timer = EventMachine::PeriodicTimer.new(heartbeat / 1000) do
        send Message::SMI.heartbeat(sid)
      end
    end

    def handle_frames(*frames)
      # we need to close frame to avoid memory leaks
      frames = frames.map do |frame|
        out_frame = frame.copy_out_string
        frame.close
        out_frame
      end

      handle Message.parse(frames)
    end

    def handle(message)
      if message.req?
        handle_request(message)
      #else
        # puts "heartbeat response received!"
      end
    rescue ZSS::Error => error
      #puts "Erorr: ZSS::Error raised while processing request: #{e}"
      reply_error error, message
    rescue => e
      #puts "Error while processing request: #{e}"
      reply_error Error[500], message
    end

    def handle_request(message)
      if message.address.sid != sid
        error = Error[404]
        error.developer_message = "Invalid SID: #{message.address.sid}!"
        fail error
      end

      # the router returns an handler that receives payload and headers
      handler = router.get(message.address.verb)
      message.payload = handler.call(message.payload, message.headers)
      reply message
    end

    def reply_error(error, message)
      message.status = error.code
      message.payload = {
        errorCode: error.code,
        userMessage: error.user_message,
        developerMessage: error.developer_message
      }
      message.type = Message::Type::REP
      send message
    end

    def reply(message)
      #puts "reply #{message}"
      message.status = 200
      message.type = Message::Type::REP
      send message
    end

    def send(msg)
      frames = msg.to_frames
      #remove identity frame on request
      frames.shift if msg.req?
      success = socket.send_msg(*frames)
      puts "An Error ocurred while sending message" unless success
    end

  end
end
