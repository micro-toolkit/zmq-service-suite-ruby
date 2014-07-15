require 'em-zeromq'
require 'msgpack'

module BrokerHelper

  LOG_BROKER_INFO = false

  def run_broker_for_client(endpoint)

    Thread.new do
      puts "broker running" if LOG_BROKER_INFO

      Thread.handle_interrupt(RuntimeError => :immediate) do

        begin
          context = ZMQ::Context.create
          socket = context.socket ZMQ::ROUTER
          socket.setsockopt(ZMQ::LINGER, 0)
          socket.bind(endpoint)
          puts "broker connected" if LOG_BROKER_INFO

          socket.recv_strings(frames = [])

          puts "broker received #{frames}" if LOG_BROKER_INFO

          if block_given?
            msg = ZSS::Message.parse(frames)

            yield(msg)

            frames = msg.to_frames
            socket.send_strings(frames)

            puts "broker reply #{frames}" if LOG_BROKER_INFO
          end
        rescue => e
          puts "WTF => #{e}"
        ensure
          # You can write resource deallocation code safely.
          puts "broker stoping" if LOG_BROKER_INFO
          socket.close if socket
          context.terminate if context
        end
      end

    end

  end

  def run_broker_for_service(endpoint, send_message = nil)
    context = EM::ZeroMQ::Context.new(1)
    socket = context.socket(ZMQ::ROUTER)
    socket.setsockopt(ZMQ::LINGER, 0)
    socket.on(:message) do |*frames|
      frames = get_frames_and_close_message(frames)
      puts "broker received #{frames}" if LOG_BROKER_INFO
      service_id = frames.shift if frames.length == 9
      msg = ZSS::Message.parse(frames)

      if msg.address.sid == 'SMI'
        handle_smi_verbs(socket, msg, send_message)
      else
        puts "check service response" if LOG_BROKER_INFO
        yield(msg) if block_given?
      end

    end

    socket.bind(endpoint)
  end

  private

  def handle_smi_verbs(socket, msg, send_message)

    if msg.address.verb == 'UP'
      msg.status = 200
      msg.type = ZSS::Message::Type::REP
      puts "broker reply to UP" if LOG_BROKER_INFO
      socket.send_msg(*msg.to_frames)

      if send_message
        send_message.identity = msg.identity
        puts "broker sending emulated client request" if LOG_BROKER_INFO
        # emulate client request
        socket.send_msg(*send_message.to_frames)
      end

    end
  end

  def get_frames_and_close_message(frames)
    frames.map do |frame|
      out_frame = frame.copy_out_string
      frame.close
      out_frame
    end
  end

end
