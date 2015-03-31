require 'spec_helper'
require 'zss/permit'

describe ZSS::Permit do

  let!(:params) do
    { arg1: 'somevalue', arg2: 'someothervalue' }
  end

  it 'filters all non permitted params' do
    ZSS::Permit::Permitter.permit(params, [ :arg1 ])
    expect(
      params
    ).to eq({ arg1: 'somevalue' })
  end

  it 'can be included' do

    class SomeClass
      include ZSS::Permit
    end

    testObject = SomeClass.new
    testObject.permit(params, :arg1)

    expect(
      params
    ).to eq({ arg1: 'somevalue' })

  end

end
