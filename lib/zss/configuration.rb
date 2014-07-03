module ZSS
  class Configuration

    def self.default
      Hashie::Mash.new frontend: 'tcp://127.0.0.1:5560'
    end

  end
end
