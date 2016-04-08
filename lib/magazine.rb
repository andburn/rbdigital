class Magazine

  attr_reader :title, :id, :cover_url

  def initialize(title, id, cover_url)
    @title = title.gsub(',','')
    @id = id
    @cover_url = cover_url
  end

  def ==(mag)
    self.id == mag.id && self.cover_url == mag.cover_url
  end

  def to_s
    "#{@title} (#{@id})"
  end

end
