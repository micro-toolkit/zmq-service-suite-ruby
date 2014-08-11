require 'json'

module ZSS
  class Error < ::StandardError

    attr_reader :code, :user_message
    attr_accessor :developer_message

    def initialize(code = 500, developer_message = nil, payload: nil)

      if payload
        fail "Invalid error code: #{code}" if code.blank?
      else
        data = self.class.get_errors[code.to_s]
        payload = data.body if data
      end

      fail "Invalid error with code: #{code}" unless payload

      @code = code.to_i
      @developer_message = developer_message || payload.developerMessage
      @user_message = payload.userMessage
      super @developer_message
      set_backtrace caller
    end

    def self.[](code)
      data = get_errors[code.to_s]
      Error.new(code.to_i, data.body)
    end

    private

    def self.get_errors
      @errors ||= begin
        path = File.join(
          File.dirname(File.absolute_path(__FILE__)),
          'errors.json'
        )
        file = File.read(path)
        Hashie::Mash.new(JSON.parse(file))
      end
    end

  end
end
