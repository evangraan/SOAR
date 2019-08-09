require 'rubygems'
require 'bundler/setup'
require 'converse'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib", "converse")

RSpec.configure do |config|

end