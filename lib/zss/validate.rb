module ZSS
  module Validate

    class Validator

      def self.is_valid_uri?(uri)
          !URI::parse(uri).relative?
      rescue
        false
      end

    end

    def is_valid_uri?(uri)
      Validator.is_valid_uri?(uri)
    end

  end
end
