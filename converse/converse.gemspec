# -*- encoding: utf-8 -*-
require File.expand_path('../lib/converse/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ernst van Graan"]
  gem.email         = ["ernst.van.graan@hetzner.co.za"]
  gem.description   = %q{Converse provides Broker/Translator classes to facilitate communication across an API by means of conversations}
  gem.summary       = %q{Converse provides Broker/Translator classes to facilitate communication across an API by means of conversations}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "converse"
  gem.require_paths = ["lib"]
  gem.version       = Converse::VERSION

  gem.add_dependency "json"
  gem.add_dependency "mysql2"
  gem.add_development_dependency "rspec"
end
