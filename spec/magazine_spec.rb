describe 'magazine' do

	before(:each) do
    @library = Rbdigital::Library.new('abc', 000)
    @magazine = Rbdigital::Magazine.new(123, @library)
  end

	describe 'get_info' do
    it 'period should be zero if a single issue' do
      get_info_stub("one_issue_only")
      expect(@magazine.period).to eq 0
    end

    it 'period should be four if monthly' do
      get_info_stub("current_issue")
      expect(@magazine.period).to eq 4
    end

    it 'period should be one if weekly' do
      get_info_stub("weekly_issue")
      expect(@magazine.period).to eq 1
    end

    it 'should be true if only back issues are available' do
      get_info_stub("back_issues_only")
      expect(@magazine.archived?).to be_truthy
    end

    it 'should be false if current issue is available' do
      get_info_stub("current_issue")
      expect(@magazine.archived?).to be_falsey
    end

    it 'should have a correct date object' do
      get_info_stub("current_issue")
      expect(@magazine.date).to eq(Date.new(2016, 5, 1))
    end

    it 'should have a correct date object with back isssue notice' do
      get_info_stub("back_issues_only")
      expect(@magazine.date).to eq(Date.new(2018, 1, 1))
    end

    it 'should have a title' do
      get_info_stub("current_issue")
      expect(@magazine.title).to eq("Android Magazine")
    end

    it 'should have a country' do
      get_info_stub("current_issue")
      expect(@magazine.country).to eq("United Kingdom")
    end

    it 'should have a genre' do
      get_info_stub("current_issue")
      expect(@magazine.genre).to eq("Computers & Technology")
    end

    it 'should have a language' do
      get_info_stub("current_issue")
      expect(@magazine.lang).to eq("English")
    end
  end

  def get_info_stub(file)
    stub_request(:get, @library.magazine_url(123)).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file("#{file}.html"), :status => 200)
      @magazine.update
  end
end
