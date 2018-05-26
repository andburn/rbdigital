module Rbdigital
  extend self

  def get_magazine_ids(library_id)
  end

  def get_magazine(library_id, magazine_id)
  end

  def checkout_magazines(library_id, user_name, user_pass, *magazine_ids)
  end

  def return_magazines(library_id, user_name, user_pass, *magazine_ids)
  end
end

require "rbdigital/version"
require "rbdigital/application"
