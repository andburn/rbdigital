class Patron

  attr_reader :user_name, :email, :password

  def initialize(user_name, email, password)
    @user_name = user_name
    @password = password
    @email = email
  end

  def to_s
    "#{user_name},#{email}"
  end

end