require 'spec_helper'

describe ZSS::Environment do

  it('returns environment string') do
    expect(subject.env).to eq('test')
  end

  it('returns true when query by current env') do
    expect(subject.env.test?).to be true
  end

  it('returns false when query for different env') do
    expect(subject.env.production?).to be false
  end

end
