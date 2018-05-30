require 'nokogiri'

require 'rbdigital/request'

module Rbdigital
  class Magazine
    attr_accessor :title, :id, :date, :genre, :country, :lang, :period
    attr_reader :archived

    def initialize(id)
      @id = id
    end

    def archived?
      return @archived
    end

    def get_info
      start_page = "http://www.rbdigital.com/abc/service/zinio/landing"
      content = Request.get(start_page + "?mag_id=" + @id.to_s)
      html = Nokogiri::HTML(content)

      date = html.at_css('p.release_date')

      # check for 'only back issues'
      back_only = date.children.at_css('span')
      if !back_only.nil? && back_only.content =~ /current subscription.+unavailable/i
        @archived = true
      end

      # get the period of issue
      @period = -1
      info = html.at_css('div.addition_info')
      issues = info.children.at_css('p:last-child')
      if !issues.nil?
        if issues.content =~ /one issue only/i
          @period = 0
        elsif issues.content =~ /monthly/i
          @period = 4
        elsif issues.content =~ /weekly/i
          @period = 1
        end
      end
    end

  end
end
