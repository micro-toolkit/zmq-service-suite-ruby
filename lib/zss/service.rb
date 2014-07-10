require_relative 'socket'
require_relative 'router'
require_relative 'message/smi'

module ZSS
  class Service

    attr_reader :sid, :heartbeat, :backend

    def initialize(sid, config = {})

      fail Error[500] if sid.blank?

      @sid = sid.to_s.upcase
      @heartbeat = config.try(:heartbeat) || 1000
      @backend   = config.try(:backend) || Configuration.default.backend

      config = Hashie::Mash.new(
        socket_address: @backend,
        identity: @sid.downcase
      )
      @socket = Socket.new config
      @router = ZSS::Router.new
    end

    def run
      #puts "Starting SID: '#{sid}' ID: '#{socket.identity}'"
      #puts "Env: #{ZSS::Environment.env}"
      #puts "Broker: #{backend}"

      start_service

    end

    def add_route(context, route, handler = nil)
      router.add(context, route, handler)
    end

    def stop
      #puts "Stoping SID: '#{sid}' ID: '#{socket.identity}'"
      stop_service
    end

    private

    attr_accessor :socket, :connected_socket,
      :heartbeat_worker, :receiver_worker,
      :running, :router

    def start_service
      socket.connect
      socket.send Message::SMI.up(sid)
      message = socket.receive
      #puts "broker replied to: #{message.address.sid}:#{message.address.verb} with #{message.status}"
      @running = true
      start_receiver_worker
      start_heartbeat_worker

      receiver_worker.join
    end

    def stop_service
      return unless running

      @running = false
      receiver_worker.terminate if receiver_worker
      heartbeat_worker.terminate if heartbeat_worker
      socket.send Message::SMI.down(sid)
      message = socket.receive
      #puts "broker replied to: #{message.address.sid}:#{message.address.verb} with #{message.status}"
      socket.disconnect
    end

    def start_heartbeat_worker

      @heartbeat_worker = Thread.new do
        Thread.handle_interrupt(RuntimeError => :immediate) do

          loop do
            begin
              # heartbeat is in ms and sleep receives seconds
              sleep(heartbeat / 1000.0)
              #puts "sending heartbeat..."
              socket.send Message::SMI.heartbeat(sid)
            rescue => e
              #puts "Heartbeat blow => #{e}"
            end
          end
        end
      end

    end

    def start_receiver_worker

      @receiver_worker = Thread.new do
        Thread.handle_interrupt(RuntimeError => :immediate) do

          while running do
            message = socket.receive

            if message
              handle message
            #else
              #puts "error: something wrong received a nil message from socket"
            end
          end

        end
      end

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
      message.status = 200
      reply message
    end

    def reply_error(error, message)
      message.status = error.code
      message.payload = {
        errorCode: error.code,
        userMessage: error.user_message,
        developerMessage: error.developer_message
      }
      reply message
    end

    def reply(message)
      #puts "reply #{message}"
      message.type = Message::Type::REP
      socket.send message
    end


  end
end
