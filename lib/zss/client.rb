require_relative '../zss'
require_relative 'socket'

module ZSS
  class Client


    attr_reader :sid, :frontend, :identity, :timeout

    def initialize(sid, config = {})
      @frontend   = config[:frontend] || Configuration.default.frontend
      @sid      = sid.to_s.upcase
      @identity = config[:identity] || "client"
      @timeout  = config[:timeout] || 1000
      @config = Hashie::Mash.new(
        socket_address: frontend,
        identity: identity,
        timeout: timeout
      )
    end

    def call(verb, payload, headers: {}, timeout: nil)
      action = verb.to_s.upcase
      address = Message::Address.new(sid: sid, verb: action)

      request = Message.new(
        address: address,
        headers: headers,
        payload: payload)

      timeout ||= config.timeout
      metadata = metadata(timeout, request)
      log.info("Request #{request.rid} sent to #{request.address} with #{timeout/1000.0}s timeout", metadata)

      response = socket.call(request, timeout)
      metadata = metadata(timeout, response)

      log.info("Received response to #{request.rid} with status #{response.status}", metadata)

      fail ZSS::Error.new(response.status, payload: response.payload) if response.is_error?

      response.payload
    rescue => e
      additional_variables = {}
      additional_variables[:address] = address.to_s if defined?(address)
      additional_variables[:metadata] = metadata if defined?(metadata)
      if defined?(response)
        additional_variables[:response] = response.to_s
        additional_variables[:response_frames] = response.to_frames if response.respond_to?(:to_frames)
      end

      params = {
        class: 'ZSS::Client',
        method: 'call',
        params: {
          method_params: {
            verb: verb,
            payload: payload,
            headers: headers,
            timeout: timeout
          },
          additional_variables: additional_variables
        }
      }

      begin
        ZSS::Notifier.notify_exception(e, params)
      rescue
        params[:params].delete(:additional_variables)
        ZSS::Notifier.notify_exception(e, params)
      end

      raise e
    end

    private

    attr_reader :config

    def method_missing(method, *args)
      # since we cannot use / on method names we replace _ with /
      verb = method.to_s.gsub('_', '/')
      payload = args[0]
      options = args[1] || {}
      call verb, payload, options
    end

    def socket
      Socket.new config
    end

    def metadata(timeout, message)
      {
        identity: identity,
        timeout: timeout,
        pid: Process.pid,
        request: message.to_log
      }
    end

  end
end
