require_relative 'socket'

module ZSS
  class Client

    include LoggerFacade::Loggable

    attr_reader :sid, :frontend, :identity, :timeout

    def initialize sid, config = {}
      @frontend   = config[:frontend] || Configuration.default.frontend
      @sid      = sid.to_s.upcase
      @identity = config[:identity] || "client"
      @timeout  = config[:timeout] || 1000
    end

    def call verb, payload, headers: {}, timeout: nil
      action = verb.to_s.upcase
      address = Message::Address.new(sid: sid, verb: action)

      request = Message.new(
        address: address,
        headers: headers,
        payload: payload)

      log.info("Request #{request.rid} sent to #{request.address} with #{timeout}s timeout")

      response = socket.call(request, timeout)

      log.info("Received response to #{request.rid} with status #{response.status}")

      fail ZSS::Error.new(response.status, response.payload) if response.is_error?

      response.payload
    end

    private

    def method_missing method, *args
      # since we cannot use / on method names we replace _ with /
      verb = method.to_s.gsub('_', '/')
      payload = args[0]
      options = args[1] || {}
      call verb, payload, options
    end

    def socket
      config = Hashie::Mash.new(
        socket_address: frontend,
        identity: identity,
        timeout: timeout
      )

      Socket.new config
    end

  end
end
