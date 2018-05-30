describe 'magazine' do

	before(:each) do
    @mag_url = "http://www.rbdigital.com/abc/service/zinio/landing?mag_id=123"
    @magazine = Rbdigital::Magazine.new(123)
  end

	describe 'get_info' do
    it 'period should be zero if a single issue' do
      stub_request(:get, @mag_url).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('one_issue_only.html'), :status => 200)
      @magazine.get_info
      expect(@magazine.period).to eq 0
    end

    it 'period should be four if monthly' do
      stub_request(:get, @mag_url).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('current_issue.html'), :status => 200)
      @magazine.get_info
      expect(@magazine.period).to eq 4
    end

    it 'period should be one if weekly' do
      stub_request(:get, @mag_url).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('weekly_issue.html'), :status => 200)
      @magazine.get_info
      expect(@magazine.period).to eq 1
    end

    it 'should be true if only back issues are available' do
      stub_request(:get, @mag_url).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('back_issues_only.html'), :status => 200)
      @magazine.get_info
      expect(@magazine.archived?).to be_truthy
    end

    it 'should be false if current issue is available' do
      stub_request(:get, @mag_url).
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('current_issue.html'), :status => 200)
      @magazine.get_info
      expect(@magazine.archived?).to be_falsey
    end
  end
end
