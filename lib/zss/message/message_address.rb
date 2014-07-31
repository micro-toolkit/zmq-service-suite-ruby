module ZSS

  class Message

    class Address
      attr_accessor :sid,
                    :sversion,
                    :verb

      def initialize args = {}
        @sid      = args[:sid].try(:upcase)
        @verb     = args[:verb].try(:upcase)
        @sversion = args[:sversion].try(:upcase) || '*'
      end
      end

    end

  end

end
