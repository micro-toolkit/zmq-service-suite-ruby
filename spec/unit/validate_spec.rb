require 'spec_helper'
require 'zss/validate'

describe ZSS::Validate do

  it 'accepts a valid uri' do

    expect(ZSS::Validate::Validator.is_valid_uri?('https://clubjudge.com')).to be

  end

  it 'denies an inclomplete uri' do

    expect(ZSS::Validate::Validator.is_valid_uri?('www.sapo.pt')).not_to be

  end

  it 'denies an erroneous url' do
    expect(URI).to receive(:parse).and_raise(StandardError)
    expect(ZSS::Validate::Validator.is_valid_uri?('somestring')).not_to be
  end

  it 'denies an invalid uri' do

    expect(ZSS::Validate::Validator.is_valid_uri?('some1nval/dUrl')).not_to be

  end

  it 'can be included' do

    class SomeClass
      include ZSS::Validate
    end

    testObject = SomeClass.new

    expect(testObject.is_valid_uri?('https://clubjudge.com')).to be

  end

end
