module Rbdigital
  extend self

  def get_magazine_ids(library_id)
  end

  def get_magazine(library_id, magazine_id)
  end

  def checkout_magazines(library_id, user_name, user_pass, *magazine_ids)
      checkout = {}
      if not magazine_ids.empty?
        library.log_out
        library.log_in(user_name, user_pass)
        if not library.logged_in?
          # TODO throw error
        end
        magazine_ids.each do |id|
          # need to wait on timed lock out to end
          # TODO shouldn't wait at start
          sleep(30)
          # checkout the latest issue
          status = library.checkout(id)
          if status =~ /^ERR/i
            # TODO throw error
          elsif status =~ /already/i
            # TODO throw error (doesn't seem to happen anymore)
          end
        end
      end
    end
  end

  def return_magazines(library_id, user_name, user_pass, *magazine_ids)
  end
end

require "rbdigital/version"
require "rbdigital/application"
