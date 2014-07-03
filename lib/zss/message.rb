require 'msgpack'
require 'hashie'

require_relative 'message/message_type'
require_relative 'message/message_address'

module ZSS
  class Message

    PROTOCOL_VERSION = "ZSS:0.0"

    attr_accessor :identity,
                  :protocol,
                  :type,
                  :rid,
                  :address,
                  :headers,
                  :status,
                  :payload

    def initialize(args = {})

      @identity     = args[:identity]
      @protocol     = args[:protocol] || PROTOCOL_VERSION
      @type         = args[:type] || Type::REQ
      @rid          = args[:rid] || SecureRandom.uuid
      @address      = args[:address]
      @headers      = args[:headers] || {}
      @status       = args[:status]
      @payload      = args[:payload]

    end

    def self.parse(frames)

      frames.unshift(nil) if frames.length == 7

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
        payload:  MessagePack.unpack(frames.shift),
      )

      if msg.payload.kind_of? Hash
        msg.payload = Hashie::Mash.new(msg.payload)
      end

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
        payload.to_msgpack
      ]
    end

    def is_error?
      status != 200
    end

  end
end
