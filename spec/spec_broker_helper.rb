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
end
