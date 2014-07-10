module ZSS

  class Message

    class SMI

      SMI = 'SMI'

      def self.down sid
        Message.new(
          address: Message::Address.new(
            sid: SMI,
            verb: 'DOWN'
          ),
          payload: sid
        )
      end

      def self.up sid
        Message.new(
          address: Message::Address.new(
            sid: SMI,
            verb: 'UP'
          ),
          payload: sid
        )
      end

      def self.heartbeat sid
        Message.new(
          address: Message::Address.new(
            sid: SMI,
            verb: 'HEARTBEAT'
          ),
          payload: sid
        )
      end

    end

  end

end
