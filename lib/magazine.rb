module App

  class Magazine

    attr_reader :title, :id, :cover_id

    def initialize(title, id, cover_id)
      @title = title
      @id = id.to_i
      @cover_id = cover_id.to_i
    end

    def ==(mag)
      self.id == mag.id
    end

    def has_same_cover?(mag)
      self.cover_id == mag.cover_id
    end

    def to_s
      "#{@title} (#{@id})"
    end

  end

end
