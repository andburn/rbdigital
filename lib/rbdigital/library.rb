require 'base64'
require 'json'
require 'date'
require 'net/http'
require 'nokogiri'

require 'rbdigital/request'
require 'rbdigital/errors'

module Rbdigital
  class Library
    attr_reader :id, :code
    attr_accessor :home_page

    AJAX_URL = 'http://www.rbdigital.com/ajaxd.php?action='
    LOGIN_URL = AJAX_URL + 'p_login'
    CATALOGUE_URL = AJAX_URL + 'zinio_landing_magazine_collection'
    CHECKOUT_URL = AJAX_URL + 'zinio_checkout_complete'
    COLLECTION_URL = AJAX_URL + 'zinio_user_issue_collection'
    REMOVE_URL = AJAX_URL + 'zinio_user_issue_collection_remove'
    CHECKOUT_WAIT = 30

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
      Rbdigital.logger.info "Sending login request for #{username}"
      Request.post(LOGIN_URL, {
          :username => username,
          :password => password,
          :remember_me => 1,
          :lib_id => @id
      })
    end

    def log_out
      Rbdigital.logger.info "Logging out clearing cookies"
      Request.clear_cookies
    end

    def logged_in?
      Rbdigital.logger.info "Requesting home page to check log in status"
      body = Request.get(@home_page)
      page = Nokogiri::HTML(body)
      welcome = page.at_css('div.navigation div.welcome')
      not welcome.nil?
    end

    def magazine_info(id)
      Rbdigital.logger.info "Getting info for mag #{id}"
      mag = { id: id }
      content = Request.get(self.magazine_url(id))
      html = Nokogiri::HTML(content)

      if html.at_css('h3.magazine_name').nil?
        Rbdigital.logger.error "Magazine #{id} not found or parse error"
        raise MagazineNotFoundError.new("Magazine #{id} not found")
      end

      mag[:title] = html.at_css('h3.magazine_name').content.strip
      date_node = html.at_css('p.release_date')
      mag[:date] = Date.parse(date_node.content)
      # check if archived, i.e. only back issues are available
      back_only = date_node.children.at_css('span')
      if !back_only.nil? && back_only.content =~ /current subscription.+unavailable/i
        mag[:archived] = true
      end

      # parse the additional info section
      info = html.at_css('div.addition_info')
      mag[:genre] = additional_info(info, 1, "genre")
      mag[:country] = additional_info(info, 2, "country")
      mag[:lang] = additional_info(info, 3, "language")

      # get the period of issue, i.e. how many weeks between issues
      period = -1
      issues = info.children.at_css('p:last-child')
      if !issues.nil?
        if issues.content =~ /(one issue only)|(n\/?a)/i
          period = 0
        elsif issues.content =~ /biannually/i
          period = 26
        elsif issues.content =~ /quarterly/i
          period = 12
        elsif issues.content =~ /monthly/i
          period = 4
        elsif issues.content =~ /bimonthly/i
          period = 2
        elsif issues.content =~ /weekly/i
          period = 1
        else
          msg = "Magazine period unknown '#{issues.content.strip}'"
          Rbdigital.logger.error msg
          raise LibraryError.new(msg)
        end
      end
      mag[:period] = period

      mag
    end

    def build_catalogue
      magazines = []
      page = 0
      # parse each page until the last page is reached
      loop do
        page += 1
        break unless build_catalogue_page(magazines, page)
        # in case of error stop after 100 pages
        break if page > 100
      end
      magazines
    end

    def build_catalogue_page(magazines, page)
      Rbdigital.logger.info "Requesting catalogue page #{page}"
      response = Request.post(CATALOGUE_URL, {
          :genre_search_line => '',
          :language_search_line => '',
          :lib_id => @id,
          :p_num => page.to_s,
          :strQueryLine => '//',
          :title_search_line => ''
      })

      Rbdigital.logger.info "Parsing catalogue page #{page}"
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
      Rbdigital.logger.info "This is the last page (#{page})"
      false
    end

    def build_collection(user_name, user_pass)
      issues = []
      page = 0

      log_out
      log_in(user_name, user_pass)
      if not logged_in?
        Rbdigital.logger.error "not logged in (#{user_name})"
        raise LoginError.new("Login failed for #{user_name}")
      end

      # parse each page until the last page is reached
      loop do
        page += 1
        break unless build_collection_page(issues, page)
        # in case of error stop after 200 pages
        break if page > 200
      end
      issues
    end

    # NOTE collection page should be in row form, not grid and max per page
    # TODO could load required preferences with request after login
    def build_collection_page(issues, page)
      uri = URI.parse(COLLECTION_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({
        :lib_id => @id,
        :content_filter => '',
        :p_num => page.to_s,
        :service_t => 'magazines'
      })
      request['Cookie'] = Request.cookies
      response = http.request(request)

      Rbdigital.logger.info "Parsing collection page #{page}"
      json = JSON.parse(response.body)
      if json.key?('status') && json['status'] == 'OK'
        content = Base64.decode64(json['content'])
        page_html = Nokogiri::HTML(content)
        mags = page_html.css('tr.magazine > td.title')
        mags.each do |m|
          anchor = m.children.css('a').first
          iss = {}
          if anchor[:href] =~ /magazine-reader\/(\d+)\?zenith_mode$/
            iss[:id] = $1
          end
          if anchor[:title] =~ /^Read\s+(\w+\s+\d+\s*,\s+\d+)\s+issue\s+of\s+(.+)$/
            iss[:date] = Date.parse($1)
            iss[:title] = $2
          end
          issues << iss
        end
        # get the last page number
        links = page_html.at_css('div.links').children.css('a')
        links.each do |l|
          if l[:title] == 'The last page'
            if l[:onclick] =~ /OnUserIssueCollectionPage\(\s*'(\d+)'\)/i
              if page < $1.to_i
                return true
              end
            end
          end
        end
      end
      Rbdigital.logger.info "This is the last page (#{page})"
      false
    end

    def checkout(id)
      Rbdigital.logger.info "Checking out mag id=#{id}"
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
			rescue Net::ReadTimeout => e
        Rbdigital.logger.error "Checkout timed out (#{e.message})"
        return false
			end

      if status =~ /^err/i
        Rbdigital.logger.error "Checkout status 'error' #{id}"
        return false
      elsif msg =~ /already/i
        Rbdigital.logger.error "Checkout status 'already' #{id}"
        return false
      else
        Rbdigital.logger.info "Magazine #{id} checkout out (#{status}: #{msg})"
        return true
      end
    end

    def checkout_magazines(user_name, user_pass, *magazine_ids)
      failed = []
      if not magazine_ids.empty?
        log_out
        log_in(user_name, user_pass)
        if not logged_in?
          Rbdigital.logger.error "not logged in (#{user_name})"
          raise LoginError.new("Login failed for #{user_name}")
        end
        # checkout each mag by id for logged in user
        magazine_ids.each do |id|
          # checkout the latest issue
          success = checkout(id)
          failed << id unless success
          # need to wait after each checkout, throttling being applied
          Rbdigital.logger.debug "Waiting #{CHECKOUT_WAIT}s before next checkout"
          sleep(CHECKOUT_WAIT)
        end
      end
      failed
    end

    def remove_issue(id)
      Rbdigital.logger.info "Removing issue id=#{id}"
      uri = URI.parse(REMOVE_URL)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({:lib_id => @id, :issue_id => id, :service_t => "magazines"})
      request['Cookie'] = Request.cookies

      status = msg = ''
      begin
        response = http.request(request)
        # to check retrieve json and get codes
        json = JSON.parse(response.body)
        status = json['status']
        msg = json['title']
      rescue Net::ReadTimeout => e
        Rbdigital.logger.error "Removal timed out (#{e.message})"
        return false
      end

      if status =~ /^ok/i
        Rbdigital.logger.info "Issue #{id} removed successfully (#{status}: #{msg})"
        return true
      else
        Rbdigital.logger.error "Removal error #{id}"
        return false
      end
    end

    def remove_issues(user_name, user_pass, *issue_ids)
      failed = []
      if not issue_ids.empty?
        log_out
        log_in(user_name, user_pass)
        if not logged_in?
          Rbdigital.logger.error "not logged in (#{user_name})"
          raise LoginError.new("Login failed for #{user_name}")
        end
        # checkout each mag by id for logged in user
        issue_ids.each do |id|
          # checkout the latest issue
          success = remove_issue(id)
          failed << id unless success
          # need to wait after each checkout, throttling being applied
          Rbdigital.logger.debug "Waiting 10s before next removal"
          sleep(10)
        end
      end
      failed
    end

    private

      def additional_info(node, child, text)
        node.children.at_css("p:nth-child(#{child})")
          .content.sub("#{text}:", "").strip
      end
  end
end
