require 'ffi-rzmq'
require 'timeout'

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

    def call(request, call_timeout = nil)
      fail Socket::Error, 'invalid request' unless request

      response = nil
      t = (call_timeout || timeout) / 1000.0

      context do |ctx|
        socket ctx do |sock|
          begin
            ::Timeout.timeout t do
              log.trace("Request #{request.rid} sent to #{request.address} with #{t}s timeout")

              send_message sock, request

              log.trace("Waiting for #{request.rid}")
              response = receive_message(sock)

            end
          rescue ::Timeout::Error
            log.info("Request #{request.rid} exit with timeout after #{t}s")
            raise ZSS::Socket::TimeoutError, "call timeout after #{t}s"
          end
        end
      end

      response
    end

    private

    def context
      ctx = ZMQ::Context.create(1)
      fail Socket::Error, 'failed to create create_context' unless ctx
      yield ctx
    ensure
      check!(ctx.terminate) if ctx
    end

    def socket(context)
      socket = context.socket ZMQ::DEALER
      fail Socket::Error, 'failed to create socket' unless socket
      socket.identity = "#{identity}##{SecureRandom.uuid}"
      socket.setsockopt(ZMQ::LINGER, 0)
      socket.connect(socket_address)

      log.trace("#{socket.identity} connected to #{socket_address}")

      yield socket
    ensure
      check!(socket.close) if socket
    end

    def send_message socket, message

      log.trace("Sending:\n #{message}") if log.is_debug

      frames = message.to_frames

      # if it's a reply should send identity
      frames.shift if message.req?
      last   = frames.pop
      frames.each { |f| check! socket.send_string f.to_s, ZMQ::SNDMORE }
      check! socket.send_string last.to_s
    end

    def receive_message(socket)
      check! socket.recv_strings(frames = [])
      message = Message.parse frames

      log.trace("Receiving: \n #{message}") if log.is_debug

      message
    end

    def check! result_code
      return if ZMQ::Util.resultcode_ok? result_code

      fail Socket::Error, "operation failed, errno [#{ZMQ::Util.errno}], " +
        "description [#{ZMQ::Util.error_string}]"
    end

  end
end
