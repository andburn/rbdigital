describe 'magazine' do

	before(:all) do
    @mag_a = App::Magazine.new("One, Two", 1293,
			"https://imgs.zinio.com/dag/500733796/2015/416318957/cover.jpg?width=200")
		@mag_b = App::Magazine.new("Splendid Shoes", 3573,
			"https://imgs.zinio.com/dag/500733796/2015/416318957/cover.jpg?width=200")
		@mag_c = App::Magazine.new("Splendid Shoes", 3573,
			"https://imgs.zinio.com/dag/500733796/2015/112445549/cover.jpg?width=200")
  end

	it 'should equate if ids and cover urls are same' do
		expect(@mag_a).to eq(@mag_a)
	end

	it 'should not equate if ids are different' do
		expect(@mag_a).not_to eq(@mag_b)
	end

	it 'should not equate if cover urls are different' do
		expect(@mag_b).not_to eq(@mag_c)
	end

	it 'should contain title and id as a string' do
		expect(@mag_c.to_s).to eq("Splendid Shoes (3573)")
	end

end
