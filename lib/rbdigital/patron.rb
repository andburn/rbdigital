module Rbdigital
  class Patron
    attr_reader :name, :email, :password, :subs

    def initialize(name, email, password, subs=nil)
      @name = name
      @password = password
      @email = email
      @subs = subs
    end

    def ==(p)
      p.name == @name && p.email == @email
    end

    def to_s
      "#{name},#{email}"
    end
  end
end
