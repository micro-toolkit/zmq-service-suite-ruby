require 'spec_helper'

describe ZSS::Error do

  let! :response do
    Hashie::Mash.new(userMessage: "user info", developerMessage: "dev info")
  end

  describe('#ctor') do

    context('on invalid code') do

      it('raises an exception when code is nil') do
        expect{ described_class.new(nil, payload: response) }.to raise_exception(RuntimeError)
      end

      it('raises an exception when code does not exist on errors.json') do
        expect{ described_class.new(0) }.to raise_exception(RuntimeError)
      end

    end

    context('with payload') do

      subject do
        described_class.new(500, payload: response)
      end

      it('returns a fullfilled error.message') do
        expect(subject.code).to eq(500)
        expect(subject.developer_message).to eq("dev info")
        expect(subject.user_message).to eq("user info")
      end

      it('returns error with dev info as error.message') do
        expect(subject.message).to eq("dev info")
      end

      it('returns error with stacktrace') do
        expect(subject.backtrace).not_to be_nil
      end

    end

    context('with default error') do

      subject { described_class.new }

      it('returns an error') do
        expect(subject.code).to eq(500)
        expect(subject.developer_message).not_to be_nil
        expect(subject.user_message).not_to be_nil
      end

    end


    context('with default error') do

      subject { described_class.new(500) }

      it('returns an error') do
        expect(subject.code).to eq(500)
        expect(subject.developer_message).not_to be_nil
        expect(subject.user_message).not_to be_nil
      end


      context('with override on developer message') do

        subject { described_class.new(500, "dev info") }

        it('returns an error') do
          expect(subject.code).to eq(500)
          expect(subject.developer_message).to eq('dev info')
        end

      end
    end

  end

  describe('.[]') do

    it('returns the error') do
      result = described_class[500]
      expect(result.code).to eq(500)
    end

  end

end
