module ZSS
  module Require

    class Requirer

      def self.requires params, attributes
        Array(attributes).each do |attribute|
          unless params[attribute].present?
            raise ZSS::Error.new(400, "Invalid parameter '#{attribute}'")
          end
        end
      end

    end

    def requires params, *attributes
      Requirer.requires(params, attributes)
    end

  end
end
