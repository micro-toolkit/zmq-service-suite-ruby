module ZSS
  class Configuration

    def self.default
      Hashie::Mash.new(
        frontend: 'tcp://127.0.0.1:7777',
        backend:  'tcp://127.0.0.1:7776'
      )
    end

  end
end
