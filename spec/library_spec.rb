describe 'Library' do

  before(:all) do
    @spec_dir = File.dirname(__FILE__)
    @id = "1234"
    @url = 'http://www.rbdigital.com/abc/service/zinio/landing'
    @library = App::Library.new(@url, @id)
  end

  before(:each) do
    @patron = instance_double("Patron",
      :name => "Tim", :email => "tim@mail.com", :password => "abc123")
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
            "email" => "tim@mail.com",
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

      @library.log_in(@patron)
      expect(stub).to have_been_requested
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
          :body => get_data_file('catalogue_small_new.html'),
          :headers => {}
        )
    end

    it 'should read a single page correctly' do
      catalogue = @library.build_catalogue_page(1, true)
      expect(@stub).to have_been_requested
      expect(catalogue.pop).to eq(7)
    end

    # TODO should handle proper multi page request
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

  describe 'archived?' do

    it 'should be true if only single issue' do
      stub_request(:get, "http://www.rbdigital.com/abc/service/zinio/landing?mag_id=123").
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('one_issue_only.html'), :status => 200)
      expect(@library.archived?(123)).to be_truthy
    end

    it 'should be true if only back issues are available' do
      stub_request(:get, "http://www.rbdigital.com/abc/service/zinio/landing?mag_id=123").
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('back_issues_only.html'), :status => 200)
      expect(@library.archived?(123)).to be_truthy
    end

    it 'should be false if current issue is available' do
      stub_request(:get, "http://www.rbdigital.com/abc/service/zinio/landing?mag_id=123").
        with(:headers => {'Accept'=>'*/*', 'Cookie'=>'', 'User-Agent'=>'Ruby'}).
        to_return(:body => get_data_file('current_issue.html'), :status => 200)
      expect(@library.archived?(123)).to be_falsey
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

    it 'should return success message when checkout is successfull' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "OK", "title": "Success!"}',
          :headers => {}
        )

      expect(@library.checkout(22)).to eq("OK: Success!")
      expect(stub).to have_been_requested
    end

    it 'should return warning when already checkout' do
      stub = stub_request(:post,
        "http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete").
        with(:body => @body, :headers => @headers).
        to_return(
          :status => 200,
          :body => '{"status": "Info", "title": "You already checked out this issue"}',
          :headers => {}
        )

      expect(@library.checkout(22)).to eq("Info: You already checked out this issue")
      expect(stub).to have_been_requested
    end

  end

end
