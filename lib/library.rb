require 'nokogiri'
require 'net/http'
require 'base64'
require 'json'

require_relative 'magazine'

class Library

  attr_reader :start_page, :cookies

  def initialize(page)
    @start_page = page
    @cookies = ''
  end

  def logged_in?
    body = get_request(@start_page)
    page = Nokogiri::HTML(body)
    welcome = page.at_css('div.navigation div.welcome')
    not welcome.nil?
  end

  def log_in(patron)
    post_request('http://www.rbdigital.com/ajaxd.php?action=p_login', {
        :email => patron.email,
        :password => patron.password,
        :remember_me => 1,
        :lib_id => 857
    })
  end

  def log_out
    @cookies = ''
  end

  def build_catalogue(url=nil)
    magazines = []
    # get first page and total pages
    first_page = build_catalogue_page(url, 1, true)
    # pop off the total pages
    total_pages = first_page.pop
    # if an error occured return empty array
    if total_pages.nil?
      return []
    end
    magazines.concat(first_page)
    # get rest of pages
    (2..total_pages).each do |i|
      magazines.concat(build_catalogue_page(url, i, false))
    end
    magazines
  end

  def build_catalogue_page(url, page, get_max_page=false)
    magazines = []

    # for testing, so can pass single html file
    if url.nil?
      response = post_request('http://www.rbdigital.com/ajaxd.php?action=zinio_landing_magazine_collection', {
          :genre_search_line => '',
          :language_search_line => '',
          :lib_id => 857,
          :p_num => page,
          :strQueryLine => '//',
          :title_search_line => ''
      })
    else
      response = get_request(url)
    end

    json = JSON.parse(response)
    if json.key?('status') && json['status'] == 'OK'
      content = Base64.decode64(json['content'])
      page_html = Nokogiri::HTML(content)
      mags = page_html.css('div.magazine')
      mags.each do |m|
        anchor = m.children.at_css('a')
        if anchor[:href] =~ /mag_id=(\d+)$/
          img = anchor.children.at_css('img')
          mag = Magazine.new(anchor[:title], $1, img[:src])
          magazines << mag
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

    uri = URI.parse('http://www.rbdigital.com/ajaxd.php?action=zinio_checkout_complete')

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({:lib_id => 857, :mag_id => id})
    request['Cookie'] = @cookies

    response = http.request(request)

    # to check retrieve json and get codes
    json = JSON.parse(response.body)
    status = json['status']
    msg = json['title']

    # if status != 'OK' # or msg == 'Success!'
    #   puts 'Error: ' + msg
    # elsif msg == 'You already checked out this issue'
    #   puts 'Info: ' + msg
    # end

    "#{status}: #{msg}"
  end

  def archived?(id)
    url = 'http://www.rbdigital.com/southdublin/service/zinio/landing?mag_id='
    content = get_request(url + id)
    html = Nokogiri::HTML(content)
    date = html.at_css('p.release_date')
    back_only = date.children.at_css('span')
    if !back_only.nil?
      if back_only.content =~ /Only Back Issues Available/i
        return true
      end
    end
    return false
  end

  private

    def post_request(url, opts)
      uri = URI.parse(url)
      response = Net::HTTP.post_form(uri, opts)
      # TODO: need to include new cookies without deleting
      # TODO: what is this actually doing
      res_hash = response.to_hash
      if res_hash.key?('set-cookie')
        @cookies = ''
        res_hash['set-cookie'].each |c| do
          print c
        end
        @cookies = res_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join
      end
      #@cookies = res_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join
      print "post:" + @cookies
      response.body
    end

    def get_request(url)
      if url !~ /^http/i
        get_local(url)
      else
        get_remote(url)
      end
    end

    def get_local(path)
      output = ''
      File.foreach(path){ |line| output += line }
      output
    end

    def get_remote(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Cookie'] = @cookies
      print "get:" + @cookies
      response = http.request(request)
      # TODO: need to check for new cookies?
      response.body
    end
end
