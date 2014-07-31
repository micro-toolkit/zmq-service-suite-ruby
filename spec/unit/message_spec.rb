require 'spec_helper'
require 'msgpack'

describe ZSS::Message do

  let(:address) { ZSS::Message::Address.new(sid: "service", verb: "verb") }

  let(:headers) { { headerval: "something" } }

  let :frames do
    [
      "identity",
      ZSS::Message::PROTOCOL_VERSION,
      ZSS::Message::Type::REP,
      "RID",
      address.instance_values.to_msgpack,
      headers.to_msgpack,
      200,
      "data".to_msgpack
    ]
  end

  let(:message) { described_class.parse(frames) }

  describe('#ctor') do

    it('returns a fullfilled message with defaults') do
      allow(SecureRandom).to receive(:uuid) { "uuid" }

      actual = described_class.new({
        address: address,
        headers: headers,
        payload: "some data"
      })

      expect(actual.identity).to be_nil
      expect(actual.protocol).to eq(ZSS::Message::PROTOCOL_VERSION)
      expect(actual.type).to eq(ZSS::Message::Type::REQ)
      expect(actual.rid).to eq("uuid")
      expect(actual.address).to eq(address)
      expect(actual.headers).to eq(headers)
      expect(actual.payload).to eq("some data")
    end

  end

  describe('#parse') do

    context('without identity') do

      let :frames do
        [
          ZSS::Message::PROTOCOL_VERSION,
          ZSS::Message::Type::REP,
          "RID",
          address.instance_values.to_msgpack,
          headers.to_msgpack,
          "200",
          "data".to_msgpack
        ]
      end

      it('returns a fullfilled message') do

        address.sversion = "sversion".upcase

        actual = described_class.parse(frames)

        expect(actual.identity).to be_nil
        expect(actual.protocol).to eq(ZSS::Message::PROTOCOL_VERSION)
        expect(actual.type).to eq(ZSS::Message::Type::REP)
        expect(actual.rid).to eq("RID")
        expect(actual.address.sid).to eq(address.sid)
        expect(actual.address.verb).to eq(address.verb)
        expect(actual.address.sversion).to eq(address.sversion)
        expect(actual.headers["headerval"]).to eq(headers[:headerval])
        expect(actual.status).to eq(200)
        expect(actual.payload).to eq("data")
      end

    end

    context('with identity') do

      it('returns a fullfilled message') do

        actual = described_class.parse(frames)

        expect(actual.identity).to eq("identity")
        expect(actual.protocol).to eq(ZSS::Message::PROTOCOL_VERSION)
        expect(actual.type).to eq(ZSS::Message::Type::REP)
        expect(actual.rid).to eq("RID")
        expect(actual.address.sid).to eq(address.sid)
        expect(actual.address.verb).to eq(address.verb)
        expect(actual.address.sversion).to eq(address.sversion)
        expect(actual.headers["headerval"]).to eq(headers[:headerval])
        expect(actual.status).to eq(200)
        expect(actual.payload).to eq("data")
      end

    end

    it('returns a message with hashie headers') do

      actual = described_class.parse(frames)

      expect(actual.headers["headerval"]).to eq(headers[:headerval])
      expect(actual.headers[:headerval]).to eq(headers[:headerval])
      expect(actual.headers.headerval).to eq(headers[:headerval])
    end

    it('returns a message with hashie payload') do
      frames[7] = { something: "data" }.to_msgpack
      actual = described_class.parse(frames)
      expect(actual.payload.something).to eq("data")
      expect(actual.payload[:something]).to eq("data")
      expect(actual.payload["something"]).to eq("data")
    end

  end

  describe('#to_s') do
    let :string_representation do
      <<-out
        FRAME 0:
          IDENTITY      : #{message.identity}
        FRAME 1:
          PROTOCOL      : #{message.protocol}
        FRAME 2:
          TYPE          : #{message.type}
        FRAME 3:
          RID           : #{message.rid}
        FRAME 4:
          SID           : #{message.address.sid}
          VERB          : #{message.address.verb}
          SVERSION      : #{message.address.sversion}
        FRAME 5:
          HEADERS       : #{message.headers.to_h}
        FRAME 6:
          STATUS        : #{message.status}
        FRAME 7:
          PAYLOAD       : #{message.payload}
      out
    end

    it('returns a string with formated frame') do
      expect(message.to_s).to eq(string_representation)
    end
  end

  describe('.to_frames') do

    let :output_frames do
      [
        "identity",
        ZSS::Message::PROTOCOL_VERSION,
        ZSS::Message::Type::REP,
        "RID",
        address.instance_values.to_msgpack,
        headers.to_msgpack,
        "200",
        "data".to_msgpack
      ]
    end

    it('returns message in frames') do
      expect(message.to_frames).to eq(output_frames)
    end

  end

  describe('.is_error') do

    it('returns false when status is 200') do
      message.status = 200
      expect(message.is_error?).to eq false
    end

    it('returns true when status is not 200') do
      message.status = 500
      expect(message.is_error?).to eq true
    end

  end

  describe('.req?') do

    it('returns true on request message') do
      message.type = ZSS::Message::Type::REQ
      expect(message.req?).to eq(true)
    end

    it('returns false on response message') do
      message.type = ZSS::Message::Type::REP
      expect(message.req?).to eq(false)
    end

  end

end
