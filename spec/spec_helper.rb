require 'rspec'
require 'simplecov'
require 'webmock/rspec'
require_relative 'helpers'

RSpec.configure do |c|
  c.include Helpers
end

SimpleCov.start do
  add_filter 'spec' # ignore specs
end

WebMock.disable_net_connect!(allow_localhost: true)

require_relative '../lib/app'
require_relative '../lib/magazine'
require_relative '../lib/library'
require_relative '../lib/patron'
require_relative '../lib/records'
require_relative '../lib/utils'
