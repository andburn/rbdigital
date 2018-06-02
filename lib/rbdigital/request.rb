require 'net/http'

# TOOD invalid uri's will cause an error, handle here or at call site
module Rbdigital
  class Request
    @@cookies = ''

    def self.cookies
      @@cookies
    end

    def self.clear_cookies
      @@cookies = ''
    end

    def self.post(url, opts)
      uri = URI.parse(url)
      response = Net::HTTP.post_form(uri, opts)
      # TODO: need to include new cookies without deleting
      res_hash = response.to_hash
      if res_hash.key?('set-cookie')
        @@cookies = ''
        res_hash['set-cookie'].each do |c|
          if c !~ /deleted/ # deleted values appearing with same names
            if c =~ /^(.*?;)/
              @@cookies += $1
            end
          end
        end
        # TODO remove
        # original , each entry grab first section before ; and join to string
        #@cookies = res_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join
      end
      response.body
    end

    def self.get(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Cookie'] = @@cookies
      response = http.request(request)
      # TODO: need to check for new cookies?
      response.body
    end
  end
end
