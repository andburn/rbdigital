require 'simplecov'
SimpleCov.start do
  add_filter 'spec' # ignore specs
end

require 'rspec'

require_relative '../lib/magazine'
require_relative '../lib/library'
require_relative '../lib/patron'
require_relative '../lib/storage'
require_relative '../lib/start'
require_relative '../lib/utils'
