module Rbdigital
  class Magazine
    attr_reader :title, :id, :cover_id

    def initialize(title, id, cover_id)
      @title = title
      @id = id.to_i
      @cover_id = cover_id.to_i
    end

    def ==(mag)
      @id == mag.id
    end

    def has_same_cover?(mag)
      @cover_id == mag.cover_id
    end

    def to_s
      "#{@title} (#{@id})"
    end
  end
end
