require 'nokogiri'
require 'base64'
require 'json'
require 'net/http'

require 'rbdigital/request'

module Rbdigital
  class Library
    attr_reader :id, :code
    attr_accessor :home_page

    AJAX_URL = 'http://www.rbdigital.com/ajaxd.php?action='
    LOGIN_URL = AJAX_URL + 'p_login'
    CATALOGUE_URL = AJAX_URL + 'zinio_landing_magazine_collection'
    CHECKOUT_URL = AJAX_URL + 'zinio_checkout_complete'

    # create the default library home page with the given library code
    # can be overwritten by assigning new value to @home_page
    def self.default_library_url(code)
      "http://www.rbdigital.com/#{code}/service/magazines/landing"
    end

    # init with the landing page url, and the library id
    def initialize(code, id)
      @id = id
      @code = code
      @home_page = self.class.default_library_url(code)
    end

    def magazine_url(id)
      "#{@home_page}?mag_id=#{id.to_s}"
    end

    def log_in(patron)
      Request.post(LOGIN_URL, {
          :username => patron.email,
          :password => patron.password,
          :remember_me => 1,
          :lib_id => @id
      })
    end

    def log_out
      Request.clear_cookies
    end

    def logged_in?
      body = Request.get(@home_page)
      page = Nokogiri::HTML(body)
      welcome = page.at_css('div.navigation div.welcome')
      not welcome.nil?
    end

    def build_catalogue()
      magazines = []
      page = 0
      # parse each page until the last page is reached
      loop do
        page += 1
        break unless build_catalogue_page(magazines, page)
      end
      magazines
    end

    def build_catalogue_page(magazines, page)
      response = Request.post(CATALOGUE_URL, {
          :genre_search_line => '',
          :language_search_line => '',
          :lib_id => @id,
          :p_num => page.to_s,
          :strQueryLine => '//',
          :title_search_line => ''
      })

      json = JSON.parse(response)
      if json.key?('status') && json['status'] == 'OK'
        content = Base64.decode64(json['content'])
        page_html = Nokogiri::HTML(content)
        mags = page_html.css('div.magazine')
        mags.each do |m|
          anchor = m.children.at_css('a')
          if anchor[:href] =~ /mag_id=(\d+)$/
            magazines << Magazine.new($1, self)
          end
        end
        # get the last page number
        links = page_html.at_css('div.links').children.css('a')
        links.each do |l|
          if l[:title] == 'The last page'
            if l[:onclick] =~ /OnMagazineCollectionSearch\(\s*'(\d+)'\)/i
              if page < $1.to_i
                return true
              end
            end
          end
        end
      end
      # should only return here if on last page
      # TODO or some failure parsing the links section
      false
    end

    def checkout(id)
      uri = URI.parse(CHECKOUT_URL)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({:lib_id => @id, :mag_id => id})
      request['Cookie'] = Request.cookies

			status = msg = ''
			begin
	      response = http.request(request)
	      # to check retrieve json and get codes
	      json = JSON.parse(response.body)
	      status = json['status']
	      msg = json['title']
			rescue Net::ReadTimeout
				# TODO edit catalogue entry so picked up next time
				Rbdigital::Logger.instance.error("Net timeout on #{id}")
			end

      "#{status}: #{msg}"
    end
  end
end
