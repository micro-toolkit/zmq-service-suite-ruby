require 'zss/socket'

module ZSS
  class Client

    attr_reader :sid, :frontend, :identity, :timeout

    def initialize sid, config = nil
      @frontend   = config.try(:frontend) || Configuration.default.frontend
      @sid      = sid.to_s.upcase
      @identity = config.try(:identity) || "client"
      @timeout  = config.try(:timeout) || 1000
    end

    def call verb, payload = nil, headers: {}, timeout: nil
      action = verb.to_s.upcase#.gsub('_', '/')
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
