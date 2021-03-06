require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'rspec/mocks'
require 'tempfile'
# require 'simplecov'
# require 'simplecov-rcov'
# require 'byebug'
require 'net/http'
require 'rack/request'



# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

$:.unshift(File.join(File.dirname(__FILE__), '..', 'smaak'))
$:.unshift(File.join(File.dirname(__FILE__), '..'))

require 'lib/smaak.rb'
require 'lib/smaak/associate.rb'
require 'lib/smaak/server.rb'
require 'lib/smaak/client.rb'
require 'lib/smaak/auth_message.rb'
require 'lib/smaak/smaak_service.rb'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  # config.expect_with(:rspec) { |c| c.syntax = :should }

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
# SimpleCov.start do
#  add_filter "/spec/"
# end

