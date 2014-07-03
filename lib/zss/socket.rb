require 'ffi-rzmq'

module ZSS
  class Socket

    class Error        < StandardError; end
    class TimeoutError < Socket::Error; end

    attr_reader :timeout, :socket_address, :identity

    def initialize config
      @identity = config.identity
      @timeout = config.timeout || 1000
      @socket_address = config.socket_address
    end

    def call request, call_timeout = nil
      fail Socket::Error, 'invalid request' unless request

      response = nil
      t = (call_timeout || timeout) / 1000.0

      context do |ctx|
        socket ctx do |sock|
          begin
            ::Timeout.timeout t do
              send_message sock, request
              response = receive_message(sock)
            end
          rescue ::Timeout::Error
            raise ZSS::Socket::TimeoutError, "call timeout after #{t}s"
          end
        end
      end

      response
    end

    private

    def context
      context = ZMQ::Context.create(1)
      fail Socket::Error, 'failed to create context' unless context
      yield context
    ensure
      check!(context.terminate) if context
    end

    def socket context
      socket = context.socket ZMQ::DEALER
      fail Socket::Error, 'failed to create socket' unless socket
      socket.identity = "#{identity}##{SecureRandom.uuid}"
      socket.setsockopt(ZMQ::LINGER, 0)
      socket.bind(socket_address)
      yield socket
    ensure
      check! socket.close if socket
    end

    def send_message socket, message
      frames = message.to_frames
      first   = frames.shift
      last   = frames.pop
      frames.each { |f| check! socket.send_string f.to_s, ZMQ::SNDMORE }
      check! socket.send_string last
    end

    def receive_message socket
      check! socket.recv_strings(frames = [])
      Message.parse frames
    end

    def check! result_code
      return if ZMQ::Util.resultcode_ok? result_code

      fail Socket::Error, "operation failed, errno [#{ZMQ::Util.errno}], " +
        "description [#{ZMQ::Util.error_string}]"
    end

  end
end
