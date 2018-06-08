require 'nokogiri'
require 'base64'
require 'json'
require 'net/http'

require 'rbdigital/request'
require 'rbdigital/magazine'

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

    # convenience function to get a magazine's url
    def magazine_url(id)
      "#{@home_page}?mag_id=#{id.to_s}"
    end

    def log_in(username, password)
      Request.post(LOGIN_URL, {
          :username => username,
          :password => password,
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

    def magazine_info(id)
      mag = Magazine.new(id)
      content = Request.get(self.magazine_url(id))
      html = Nokogiri::HTML(content)

      mag.title = html.at_css('h3.magazine_name').content.strip
      date_node = html.at_css('p.release_date')
      mag.date = Date.parse(date_node.content)
      # check if archived, i.e. only back issues are available
      back_only = date_node.children.at_css('span')
      if !back_only.nil? && back_only.content =~ /current subscription.+unavailable/i
        mag.archived = true
      end

      # parse the additional info section
      info = html.at_css('div.addition_info')
      mag.genre = additional_info(info, 1, "genre")
      mag.country = additional_info(info, 2, "country")
      mag.lang = additional_info(info, 3, "language")

      # get the period of issue, i.e. how many weeks between issues
      period = -1
      issues = info.children.at_css('p:last-child')
      if !issues.nil?
        if issues.content =~ /(one issue only)|(n\/a)/i
          period = 0
        elsif issues.content =~ /monthly/i
          period = 4
        elsif issues.content =~ /weekly/i
          period = 1
        end
      end
      mag.period = period

      mag
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
            magazines << $1
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
				# TODO return an error
			end

      "#{status}: #{msg}"
    end

    def checkout_magazines(user_name, user_pass, *magazine_ids)
      if not magazine_ids.empty?
        library.log_out
        library.log_in(user_name, user_pass)
        if not library.logged_in?
          # TODO throw error
        end
        magazine_ids.each do |id|
          # need to wait on timed lock out to end
          # TODO shouldn't wait at start
          sleep(30)
          # checkout the latest issue
          status = library.checkout(id)
          if status =~ /^ERR/i
            # TODO throw error
          elsif status =~ /already/i
            # TODO throw error (doesn't seem to happen anymore)
          end
        end
      end
  end

    private

      def additional_info(node, child, text)
        node.children.at_css("p:nth-child(#{child})")
          .content.sub("#{text}:", "").strip
      end
  end
end
