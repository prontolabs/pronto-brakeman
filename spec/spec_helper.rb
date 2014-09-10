require 'rspec'
require 'rspec/its'
require 'pronto/brakeman'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
end
