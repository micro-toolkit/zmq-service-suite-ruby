require 'spec_helper'
require 'zss/require'

describe ZSS::Require do

  it 'raises 400 if any attributes are missing' do

    expect{
      ZSS::Require::Requirer.requires({ arg1: 'somevalue' }, [ :arg1, :arg2 ])
    }.to raise_error(ZSS::Error) do |e|
      expect(e.code).to eq(400)
    end

  end

  it 'accepts when all params are set' do
    expect(
      ZSS::Require::Requirer.requires({ arg1: 'somevalue', arg2: 'someothervalue' }, [ :arg1, :arg2 ])
    ).to be
  end

  it 'can be included' do

    class SomeClass
      include ZSS::Require
    end

    testObject = SomeClass.new

    expect{
      testObject.requires({ arg1: 'somevalue' }, [ :arg1, :arg2 ])
    }.to raise_error(ZSS::Error) do |e|
      expect(e.code).to eq(400)
    end

  end

end
