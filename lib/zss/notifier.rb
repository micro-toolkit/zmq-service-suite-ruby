module ZSS
  module Notifier
    module_function

    public def notify_exception(*args)
      return if PartyFoul.oauth_token.blank?

      params = data[:class] && data[:method] ? data : { class: '', method: '', params: data }
      PartyFoul::RacklessExceptionHandler.handle exception, params: data

      return if !defined?(::Notifier) || !::Notifier.respond_to?(:notify_exception)

      ::Notifier.notify_exception(*args)
    end
  end
end
