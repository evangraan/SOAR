require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'simplecov'
require 'simplecov-rcov'
#require 'byebug'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'wadling'))
$:.unshift(File.join(File.dirname(__FILE__), '..'))

require 'lib/wadling.rb'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  #config.expect_with(:rspec) { |c| c.syntax = :should }

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
end

