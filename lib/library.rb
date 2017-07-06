require 'nokogiri'
require 'net/http'
require 'base64'
require 'json'

require_relative 'magazine'

module App

  class Library

    AJAX_URL = 'http://www.rbdigital.com/ajaxd.php?action='
    LOGIN_URL = AJAX_URL + 'p_login'
    CATALOGUE_URL = AJAX_URL + 'zinio_landing_magazine_collection'
    CHECKOUT_URL = AJAX_URL + 'zinio_checkout_complete'

    attr_reader :start_page, :cookies, :id

    # init with the landing page url, and the library id
    def initialize(page, id)
      @start_page = page
      @id = id
      @cookies = ''
    end

    def log_in(patron)
      post_request(LOGIN_URL, {
          :username => patron.email,
          :password => patron.password,
          :remember_me => 1,
          :lib_id => @id
      })
    end

    def log_out
      # clear cookies
      @cookies = ''
    end

    def logged_in?
      body = get_request(@start_page)
      page = Nokogiri::HTML(body)
      welcome = page.at_css('div.navigation div.welcome')
      not welcome.nil?
    end

    def build_catalogue()
      magazines = []
      # get first page and total pages
      first_page = build_catalogue_page(1, true)
      # pop off the total pages
      total_pages = first_page.pop
      # if an error occured return empty array
      if total_pages.nil?
        return []
      end
      magazines.concat(first_page)
      # get rest of pages
      (2..total_pages).each do |i|
        magazines.concat(build_catalogue_page(i, false))
      end
      magazines
    end

    def build_catalogue_page(page, get_max_page=false)
      magazines = []

      response = post_request(CATALOGUE_URL, {
          :genre_search_line => '',
          :language_search_line => '',
          :lib_id => @id,
          :p_num => page,
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
            img = anchor.children.at_css('img')
            mag_id = $1
            if img[:src] =~ %r!imgs.zinio.com/\w+/\d+/\d+/(\d+)/\w+.jpg!
              mag = Magazine.new(anchor[:title], mag_id, $1)
              magazines << mag
            else
              App::Logger.instance.error("img url format error #{img[:src]}")
            end
          end
        end
        # get the total number of available pages
        if get_max_page
          links = page_html.at_css('div.links').children.css('a')
          links.each do |l|
            if l[:title] == 'The last page'
              if l[:onclick] =~ /OnMagazineCollectionSearch\(\s*'(\d+)'\)/i
                magazines << $1.to_i
              end
            end
          end
        end
      end

      magazines
    end

    def checkout(id)
      uri = URI.parse(CHECKOUT_URL)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({:lib_id => @id, :mag_id => id})
      request['Cookie'] = @cookies

			status = msg = ''
			begin
	      response = http.request(request)
	      # to check retrieve json and get codes
	      json = JSON.parse(response.body)
	      status = json['status']
	      msg = json['title']
			rescue Net::ReadTimeout
				# TODO edit catalogue entry so picked up next time
				App::Logger.instance.error("Net timeout on #{id}")
			end

      "#{status}: #{msg}"
    end

    def archived?(id)
      content = get_request(@start_page + "?mag_id=" + id.to_s)
      html = Nokogiri::HTML(content)
      # check for 'only back issues'
      date = html.at_css('p.release_date')
      back_only = date.children.at_css('span')
      if !back_only.nil? && back_only.content =~ /only back issues.+available/i
        return true
      end
      # check for 'one issue only'
      info = html.at_css('div.addition_info')
      issues = info.children.at_css('p:last-child')
      if !issues.nil? && issues.content =~ /(one issue only)|(na)/i
        return true
      end
      # otherwise its not archived
      return false
    end

    private

      def post_request(url, opts)
        uri = URI.parse(url)
        response = Net::HTTP.post_form(uri, opts)
        # TODO: need to include new cookies without deleting
        res_hash = response.to_hash
        if res_hash.key?('set-cookie')
          @cookies = ''
          res_hash['set-cookie'].each do |c|
            if c !~ /deleted/ # deleted values appearing with same names
              if c =~ /^(.*?;)/
                @cookies += $1
              end
            end
          end
          # original , each entry grab first section before ; and join to string
          #@cookies = res_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join
        end
        response.body
      end

      def get_request(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Cookie'] = @cookies
        response = http.request(request)
        # TODO: need to check for new cookies?
        response.body
      end

  end

end
