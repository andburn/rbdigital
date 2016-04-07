describe 'Patron' do

  before(:all) do
    @patron = App::Patron.new('joe','joe@90.com', '4922', [1, 2])
  end

  it 'should be able to access properties' do
    expect(@patron.user_name).to eq('joe')
    expect(@patron.email).to eq('joe@90.com')
    expect(@patron.password).to eq('4922')
    expect(@patron.subs).to eq([1, 2])
  end

  it 'should allow no subs param in constructor' do
    expect(App::Patron.new('a','b', 'c').subs).to be_nil
  end

  it 'should not be possible to modify properties' do
    expect {
      @patron.password = '3344'
    }.to raise_error NoMethodError
  end

  it 'should converted to a string as name comma email' do
    expect(@patron.to_s).to eq("joe,joe@90.com")
  end

  it 'should be equal if the fields are the same' do
    expect(@patron).to eq(App::Patron.new('joe','joe@90.com', '4922', [1, 2]))
  end

end
