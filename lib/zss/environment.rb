module ZSS
  module Environment

    extend self

    def env
      environment = ENV['ZSS_ENV'] || 'development'
      ActiveSupport::StringInquirer.new environment
    end

  end
end
