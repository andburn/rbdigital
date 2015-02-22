require 'digest'
require 'base64'

class Magazine

  attr_reader :title, :id, :cover_url, :issue_hash

  def initialize(title, id, cover_url)
    @title = title.gsub(',','')
    @id = id
    @cover_url = cover_url
    @issue_hash = calculate_hash(cover_url)
  end

  def ==(mag)
    self.id == mag.id && self.issue_hash == mag.issue_hash
  end

  def hash
    self.issue_hash.hash
  end

  def to_s
    "#{@title} (#{@id}) - #{issue_hash}"
  end

  private

    def calculate_hash(message)
      rmd = Digest::RMD160.new
      Base64::strict_encode64(rmd.digest(message))
    end

end