require 'ffi-rzmq'
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

    Thread.new do
      puts "broker running" if LOG_BROKER_INFO

      Thread.handle_interrupt(RuntimeError => :immediate) do

        begin
          context = ZMQ::Context.create
          socket = context.socket ZMQ::ROUTER
          socket.setsockopt(ZMQ::LINGER, 0)
          socket.bind(endpoint)
          puts "broker connected" if LOG_BROKER_INFO

          puts "broker waiting up" if LOG_BROKER_INFO
          identity = wait_for_up_and_reply(socket)

          if send_message
            send_message.identity = identity
            puts "broker sending emulated client request" if LOG_BROKER_INFO
            # emulate client request
            socket.send_strings(send_message.to_frames)
          end

          puts "broker wait for response" if LOG_BROKER_INFO
          socket.recv_strings(frames = [])
          #reply to broker client identity to route
          frames.shift
          puts "broker received #{frames}" if LOG_BROKER_INFO

          msg = ZSS::Message.parse(frames)
          yield(msg) if block_given?

          puts "broker wait down" if LOG_BROKER_INFO
          wait_for_down_and_reply(socket)
        rescue => e
          puts "WTF => #{e} : #{e.backtrace}"
        ensure
          # You can write resource deallocation code safely.
          puts "broker stoping" if LOG_BROKER_INFO
          socket.close if socket
          context.terminate if context
        end
      end

    end

  end

  private

  def wait_for_up_and_reply(socket)
    socket.recv_strings(frames = [])
    msg = ZSS::Message.parse(frames)
    # reply with 200
    msg.status = 200
    msg.type = ZSS::Message::Type::REP
    socket.send_strings(msg.to_frames)
    msg.identity
  end

  def wait_for_down_and_reply(socket)
    socket.recv_strings(frames = [])
    msg = ZSS::Message.parse(frames)
    # reply with 200
    msg.status = 200
    msg.type = ZSS::Message::Type::REP
    socket.send_strings(msg.to_frames)
  end

end
