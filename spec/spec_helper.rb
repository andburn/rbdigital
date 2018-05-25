require 'rspec'
require 'coveralls'
require 'simplecov'
require 'webmock/rspec'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec' # ignore specs
end

WebMock.disable_net_connect!(allow_localhost: true)

require 'rbdigital/application'
require 'rbdigital/magazine'
require 'rbdigital/library'
require 'rbdigital/patron'
require 'rbdigital/records'
require 'rbdigital/utils'
