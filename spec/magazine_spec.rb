describe 'magazine' do

	before(:all) do
    @a = App::Magazine.new("Fab Feet", 1293, 416318957)
		@b = App::Magazine.new("Splendid Shoes", "3573", "416318957")
		@c = App::Magazine.new("Splendid Shoes", 3573, 112445549)
  end

	it 'should be immutable' do
		expect {
      @a.title = 'new'
    }.to raise_error NoMethodError
		expect {
      @a.id = 12345
    }.to raise_error NoMethodError
		expect {
      @a.cover_id = 123
    }.to raise_error NoMethodError
	end

	it 'should equate if ids are the same' do
		expect(@a).to eq @a
		expect(@b).to eq @c
	end

	it 'should not equate if ids are different' do
		expect(@a).not_to eq @b
	end

	it 'should contain title and id as a string' do
		expect(@c.to_s).to eq "Splendid Shoes (3573)"
	end

	describe 'has_same_cover?' do

		it 'should be true if cover ids are the same' do
			expect(@a.has_same_cover? @b).to be true
		end

		it 'should not be true if cover ids are the different' do
			expect(@b.has_same_cover?(@c)).to be false
		end

	end

end
