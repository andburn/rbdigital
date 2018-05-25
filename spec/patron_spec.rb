describe 'Patron' do

  before(:all) do
    @patron = Rbdigital::Patron.new('joe','joe@90.com', '4922', [1, 2])
  end

  it 'should be immutable' do
    expect {
      @patron.name = 'Joe'
    }.to raise_error NoMethodError
    expect {
      @patron.email = 'new@example.com'
    }.to raise_error NoMethodError
    expect {
      @patron.password = '3344'
    }.to raise_error NoMethodError
    expect {
      @patron.subs = []
    }.to raise_error NoMethodError
  end

  it 'should allow no subs param in constructor' do
    expect(Rbdigital::Patron.new('a','b', 'c').subs).to be_nil
  end

  it 'should be converted to a string as name comma email' do
    expect(@patron.to_s).to eq("joe,joe@90.com")
  end

  it 'should be equal if name and email are the same' do
    expect(@patron).to eq(Rbdigital::Patron.new('joe','joe@90.com', '234', [5]))
  end

end
