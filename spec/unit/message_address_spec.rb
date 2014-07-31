require 'spec_helper'

describe ZSS::Message::Address do

  describe('#ctor') do

    it('returns a address object with default version') do
      actual = described_class.new sid: "service", verb: "verb"
      expect(actual.sid).to eq("SERVICE")
      expect(actual.verb).to eq("VERB")
      expect(actual.sversion).to eq("*")
    end

    it('returns a address object with specific version') do
      actual = described_class.new sid: "service", verb: "verb", sversion: 'v.1'
      expect(actual.sid).to eq("SERVICE")
      expect(actual.verb).to eq("VERB")
      expect(actual.sversion).to eq("V.1")
    end

  end

  describe("#to_s") do

    it('returns a address in string format') do
      actual = described_class.new sid: "service", verb: "verb", sversion: 'v.1'
      expect(actual.to_s).to eq("SERVICE:V.1#VERB")
    end
  end

end
