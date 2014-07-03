module ZSS
  class Error < ::StandardError

    attr_reader :code, :developer_message, :user_message

    def initialize code, payload
      @code = code.to_i
      @developer_message = payload.developerMessage
      @user_message = payload.userMessage
      super @developer_message
      set_backtrace caller
    end

  end
end
