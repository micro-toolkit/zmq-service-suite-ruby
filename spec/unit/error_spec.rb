require 'spec_helper'

describe ZSS::Error do

  let! :response do
    Hashie::Mash.new(userMessage: "user info", developerMessage: "dev info")
  end

  subject do
    described_class.new(500, response)
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
