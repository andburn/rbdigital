require 'nokogiri'

require 'rbdigital/request'

module Rbdigital
  class Magazine
    attr_accessor :title, :id, :date, :genre, :country, :lang, :period
    attr_reader :archived

    def initialize(id, library)
      @id = id
      @library = library
    end

    def archived?
      return @archived
    end

    def update
      content = Request.get(@library.magazine_url(@id))
      html = Nokogiri::HTML(content)

      @title = html.at_css('h3.magazine_name').content.strip
      date_node = html.at_css('p.release_date')
      @date = Date.parse(date_node.content)
      # check if archived, i.e. only back issues are available
      back_only = date_node.children.at_css('span')
      if !back_only.nil? && back_only.content =~ /current subscription.+unavailable/i
        @archived = true
      end

      # parse the additional info section
      info = html.at_css('div.addition_info')
      @genre = additional_info(info, 1, "genre")
      @country = additional_info(info, 2, "country")
      @lang = additional_info(info, 3, "language")

      # get the period of issue, i.e. how many weeks between issues
      @period = -1
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

    private

      def additional_info(node, child, text)
        node.children.at_css("p:nth-child(#{child})")
          .content.sub("#{text}:", "").strip
      end

  end
end
