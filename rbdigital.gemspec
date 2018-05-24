# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbdigital/version"

Gem::Specification.new do |spec|
  spec.name          = "rbdigital"
  spec.version       = Rbdigital::VERSION
  spec.authors       = ["Andrew Burnett"]
  spec.email         = ["andrew@andburn.info"]

  spec.summary       = %q{Checkout magazines using your RBDigital account.}
  spec.description   = %q{Provides a simple API to checkout magazines and get information about a particular magazine.}
  spec.homepage      = "https://github.com/andburn/rbdigital"
  spec.license       = "UNLICENSE"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.8"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "coveralls", "~> 0.8"
  spec.add_development_dependency "simplecov", "~> 0.14"
  spec.add_development_dependency "webmock", "~> 3.4"
end
