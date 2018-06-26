module Rbdigital
  class LibraryError < StandardError
    def initialize(message)
      super(message)
    end
  end

  class MagazineNotFoundError < LibraryError
    def initialize(message)
      super(message)
    end
  end

  class LoginError < LibraryError
    def initialize(message)
      super(message)
    end
  end

  class CheckoutError < LibraryError
    def initialize(message)
      super(message)
    end
  end
end
