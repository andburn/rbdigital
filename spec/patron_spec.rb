require 'rspec'
require_relative '../lib/patron'

describe 'Patron' do

  before(:all) do
    @patron = Patron.new('joe','joe@90.com', '4922')
  end

  it 'should be able to access properties' do
    expect(@patron.user_name).to eq('joe')
    expect(@patron.email).to eq('joe@90.com')
    expect(@patron.password).to eq('4922')
  end

  it 'should not be possible to modify properties' do
    expect {
      @patron.password = '3344'
    }.to raise_error NoMethodError
  end

end