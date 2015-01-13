require 'msgpack'
require 'hashie'

require_relative 'message/message_type'
require_relative 'message/message_address'

module ZSS
  class Message

    CLIENT_ID_REGEX = /^(.+?)#/

    PROTOCOL_VERSION = "ZSS:0.0"

    attr_accessor :client,
                  :identity,
                  :protocol,
                  :type,
                  :rid,
                  :address,
                  :headers,
                  :status,
                  :payload,
                  :payload_size

    def initialize(args = {})

      @identity     = args[:identity]
      @protocol     = args[:protocol] || PROTOCOL_VERSION
      @type         = args[:type] || Type::REQ
      @rid          = args[:rid] || SecureRandom.uuid
      @address      = args[:address]
      @headers      = args[:headers] || {}
      @status       = args[:status]
      @payload      = args[:payload]
      @client       = nil
      @payload_size  = args[:payload_size]

      match = identity.try(:match, CLIENT_ID_REGEX)
      @client = match.captures.first if match
    end

    def payload=(payload)
      @payload = payload
      @payload_msgpack_data = nil
      @payload_size = payload_msgpack.length
    end

    def req?
      type == Type::REQ
    end

    def self.parse(frames)

      frames.unshift(nil) if frames.length == 7

      payload_data = frames[7]
      payload_size = payload_data.length
      payload = MessagePack.unpack(payload_data)
      payload = Hashie::Mash.new(payload) if payload.kind_of? Hash

      msg = Message.new(
        identity: frames.shift,
        protocol: frames.shift,
        type:     frames.shift,
        rid:      frames.shift,
        address:  Address.new(
          MessagePack.unpack(frames.shift).with_indifferent_access
        ),
        headers:  Hashie::Mash.new(MessagePack.unpack(frames.shift)),
        status:   frames.shift.to_i,
        payload:  payload,
        payload_size: payload_size
      )

      msg
    end

    def to_s
      <<-out
        FRAME 0:
          IDENTITY      : #{identity}
        FRAME 1:
          PROTOCOL      : #{protocol}
        FRAME 2:
          TYPE          : #{type}
        FRAME 3:
          RID           : #{rid}
        FRAME 4:
          SID           : #{address.sid}
          VERB          : #{address.verb}
          SVERSION      : #{address.sversion}
        FRAME 5:
          HEADERS       : #{headers.to_h}
        FRAME 6:
          STATUS        : #{status}
        FRAME 7:
          PAYLOAD       : #{payload}
      out
    end

    def to_frames
      [
        identity,
        protocol,
        type,
        rid,
        address.instance_values.to_msgpack,
        headers.to_h.to_msgpack,
        status.to_s,
        payload_msgpack
      ]
    end

    def to_log
      {
        client: client,
        identity: identity,
        protocol: protocol,
        type: type,
        rid: rid,
        address: address,
        headers: headers,
        status: status,
        payload: big? ? "<<Message to big to log>>" : payload,
        "payload-size" => payload_size
      }
    end

    def is_error?
      status != 200
    end

    def big?
      payload_size = payload_msgpack.length unless payload_size
      payload_size > 1024
    end

    def payload_msgpack
      # this will avoid executing multiple serializations
      @payload_msgpack_data ||= payload.to_msgpack
    end

  end
end
