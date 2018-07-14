require 'rspec'
require 'coveralls'
require 'simplecov'
require 'webmock/rspec'

require 'file_helper'

RSpec.configure do |c|
  c.include FileHelper
end

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec' # ignore specs
end

WebMock.disable_net_connect!(allow_localhost: true)

require 'rbdigital'
require 'rbdigital/request'
require 'rbdigital/library'

# don't show error log messages on test run
require 'log4r'

Rbdigital.set_log_level(Log4r::FATAL)
