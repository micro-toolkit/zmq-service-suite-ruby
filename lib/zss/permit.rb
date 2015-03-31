module ZSS
  module Permit

    class Permitter

      def self.permit params, attributes
        params.keep_if do |k, _|
          Array(attributes).include? k.to_sym
        end
      end

    end

    def permit params, *attributes
      Permitter.permit(params, attributes)
    end

  end
end
