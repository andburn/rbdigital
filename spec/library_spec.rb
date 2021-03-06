describe 'Library' do

  before(:all) do
    @id = "1234"
    @code = "abc"
    @url = Rbdigital::Library.default_library_url(@code)
    @library = Rbdigital::Library.new(@code, @id)
    @user = { email: "tim@mail.com", password: "abc123" }
  end

  describe 'logged_in?' do

    it 'should be false when logged out' do
      stub_request(:get, @url).
        to_return(:body => get_data_file('logged_out.html'), :status => 200)
      expect(@library.logged_in?).to be_falsey
    end

    it 'should be true when logged in' do
      stub_request(:get, @url).
        to_return(:body => get_data_file('logged_in.html'), :status => 200)
      expect(@library.logged_in?).to be_truthy
    end

    it 'should be false when html is unknown' do
      stub_request(:get, @url).to_return(body: "<h1>Random</h1>", :status => 200)
      expect(@library.logged_in?).to be_falsey
    end

  end

  describe 'log_in' do

    it 'should post request with credentials' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=p_login").
        with(
          :body => {
            "username" => "tim@mail.com",
            "password" => "abc123",
            "lib_id" => @id,
            "remember_me" => "1"
          },
          :headers => {
            'Accept' => '*/*',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Host' => 'www.rbdigital.com',
            'User-Agent' => 'Ruby'
          }).to_return(:status => 200, :body => "", :headers => {})

      @library.log_in(@user[:email], @user[:password])
      expect(stub).to have_been_requested
    end

  end

  describe 'magazine_info' do
    before(:all) do
      @library = Rbdigital::Library.new('abc', 000)
      @magazine_id = 123
    end

    def get_info_stub(file)
      stub_request(:get, @library.magazine_url(@magazine_id)).
          with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
          to_return(:body => get_data_file("#{file}.html"), :status => 200)
      @library.magazine_info(@magazine_id)
    end

    it 'period should be zero if a single issue' do
      @magazine = get_info_stub("one_issue_only")
      expect(@magazine[:period]).to eq 0
    end

    it 'period should be four if monthly' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:period]).to eq 4
    end

    it 'period should be one if weekly' do
      @magazine = get_info_stub("weekly_issue")
      expect(@magazine[:period]).to eq 1
    end

    it 'should be true if only back issues are available' do
      @magazine = get_info_stub("back_issues_only")
      expect(@magazine[:archived]).to be_truthy
    end

    it 'should be false if current issue is available' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:archived]).to be_falsey
    end

    it 'should have a correct date object' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:date]).to eq(Date.new(2016, 5, 1))
    end

    it 'should have a correct date object with back isssue notice' do
      @magazine = get_info_stub("back_issues_only")
      expect(@magazine[:date]).to eq(Date.new(2018, 1, 1))
    end

    it 'should have a title' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:title]).to eq("Android Magazine")
    end

    it 'should have a country' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:country]).to eq("United Kingdom")
    end

    it 'should have a genre' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:genre]).to eq("Computers & Technology")
    end

    it 'should have a language' do
      @magazine = get_info_stub("current_issue")
      expect(@magazine[:lang]).to eq("English")
    end
  end

  describe 'build_catalogue' do

    before(:each) do
      @stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_landing_magazine_collection").
        with(
          :body => {
            "genre_search_line" => '',
            "language_search_line" => '',
            "lib_id" => @id,
            "p_num" => /\d+/,
            "strQueryLine" => '//',
            "title_search_line" => ''
          },
          :headers => {
            'Accept'=>'*/*',
            'Content-Type'=>'application/x-www-form-urlencoded',
            'Host'=>'www.rbdigital.com',
            'User-Agent'=>'Ruby'
          }
        ).
        to_return(
          :status => 200,
          :body => get_data_file('catalogue_small.html'),
          :headers => {}
        )
    end

    it 'should read a single page correctly' do
      mags = []
      more_pages = @library.build_catalogue_page(mags, 1)
      expect(@stub).to have_been_requested
      expect(more_pages).to be_truthy
      expect(mags.length).to eq(4)
    end

    it 'should create a list of all available magazines' do
      catalogue = @library.build_catalogue()
      expect(@stub).to have_been_requested.times(7)
      expect(catalogue.length).to eq(28)
    end

    it 'should handle an error in getting catalogue' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_landing_magazine_collection").
        with(:body => {}, :headers => { 'Host'=>'www.rbdigital.com', 'User-Agent'=>'Ruby' }).
        to_return(:status => 200, :body => get_data_file('catalogue_error.html'), :headers => {})

      catalogue = @library.build_catalogue()
      expect(stub).to have_been_requested
      expect(catalogue.length).to eq(0)
    end

  end

  describe 'checkout' do

    before(:all) do
      @body = {"lib_id"=>@id, "mag_id"=>"22"}
      @headers = {
        'Accept'=>'*/*',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent'=>'Ruby',
        'Cookie'=>''
      }
    end

    it 'should return true when checkout is successfull' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "OK", "title": "Success!"}',
          :headers => {}
        )

      expect(@library.checkout(22)).to be_truthy
      expect(stub).to have_been_requested
    end

    it 'should return false when already checkout' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "Info", "title": "You already checked out this issue"}',
          :headers => {}
        )

      expect(@library.checkout(22)).to be_falsey
      expect(stub).to have_been_requested
    end

    it 'should return false on checkout error' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "ERR", "title": "Something went wrong"}',
          :headers => {}
        )

      expect(@library.checkout(22)).to be_falsey
      expect(stub).to have_been_requested
    end

  end

  describe 'build_collection' do
    before(:each) do
      @stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_user_issue_collection").
        with(
          :body => {
            "content_filter" => '',
            "lib_id" => @id,
            "p_num" => /\d+/,
            "service_t" => 'magazines'
          },
          :headers => {
            'Accept'=>'*/*',
            'Cookie'=>'',
            'Content-Type'=>'application/x-www-form-urlencoded',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'=>'Ruby'
          }
        ).
        to_return(
          :status => 200,
          :body => get_data_file('collection_small.html'),
          :headers => {}
        )
    end

    it 'should read a single page correctly' do
      issues = []
      more_pages = @library.build_collection_page(issues, 1)
      first = issues.first

      expect(@stub).to have_been_requested
      expect(more_pages).to be_truthy
      expect(issues.length).to eq(5)
      expect(first[:id]).to eq("415875")
      expect(first[:title]).to eq("Radio Times")
      expect(first[:date]).to eq(Date.new(2018, 10, 26))
      expect(issues.last[:id]).to eq("402538")
    end

    it 'should create a list of all issues in collection' do
      login_stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=p_login")
        .with(
          body: {
            "lib_id"=>@id,
            "password"=>"pass",
            "remember_me"=>"1",
            "username"=>"user"
          },
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Type'=>'application/x-www-form-urlencoded',
            'Host'=>'www.rbdigital.com',
            'User-Agent'=>'Ruby'
          }
        ).to_return(status: 200, body: "", headers: {})
      login_check_stub = stub_request(:get, @url).
        to_return(:body => get_data_file('logged_in.html'), :status => 200)

      issues = @library.build_collection('user', 'pass')
      expect(login_stub).to have_been_requested.times(1)
      expect(login_check_stub).to have_been_requested.times(1)
      expect(@stub).to have_been_requested.times(8)
      expect(issues.length).to eq(40)
    end
  end

  describe 'remove_issue' do
    before(:all) do
      @body = {"lib_id"=>@id, "issue_id" => '2222', "service_t" => 'magazines'}
      @headers = {
        'Accept'=>'*/*',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent'=>'Ruby',
        'Cookie'=>''
      }
    end

    it 'should return true when removal is successfull' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_user_issue_collection_remove").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "OK", "title": "Success!"}',
          :headers => {}
        )

      expect(@library.remove_issue(2222)).to be_truthy
      expect(stub).to have_been_requested
    end

    it 'should return false when removal is unsuccessfull' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_user_issue_collection_remove").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "ERR", "title": "ERROR"}',
          :headers => {}
        )

      expect(@library.remove_issue(2222)).to be_falsey
      expect(stub).to have_been_requested
    end
  end
end
