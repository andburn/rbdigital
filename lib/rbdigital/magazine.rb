module Rbdigital
  class Magazine
    attr_accessor :title, :id, :date, :genre, :country, :lang, :period, :archived

    def initialize(id)
      @id = id
    end

    def archived?
      return @archived
    end
  end
end
