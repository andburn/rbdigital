module App
  class Patron

    attr_reader :user_name, :email, :password, :subs

    def initialize(user_name, email, password, subs=nil)
      @user_name = user_name
      @password = password
      @email = email
      @subs = subs
    end

    def ==(p)
      p.user_name == @user_name && p.email == @email && p.password == @password
    end

    def to_s
      "#{user_name},#{email}"
    end

  end
end
