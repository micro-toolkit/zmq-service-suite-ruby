require_relative 'socket'

module ZSS
  class Client

    attr_reader :sid, :frontend, :identity, :timeout

    def initialize sid, config = {}
      @frontend   = config[:frontend] || Configuration.default.frontend
      @sid      = sid.to_s.upcase
      @identity = config[:identity] || "client"
      @timeout  = config[:timeout] || 1000
    end

      action = verb.to_s.upcase#.gsub('_', '/')
    def call verb, payload, headers: {}, timeout: nil
      address = Message::Address.new(sid: sid, verb: action)

      request = Message.new(
        address: address,
        headers: headers,
        payload: payload)

      response = socket.call(request)
      fail ZSS::Error.new(response.status, response.payload) if response.is_error?

      response.payload
    end

    private

    def method_missing method, payload = nil, headers: {}
      # since we cannot use / on method names we replace _ with /
      verb = method.to_s.gsub('_', '/')
      call verb, payload, headers: headers
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
