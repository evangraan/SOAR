# -*- encoding: utf-8 -*-
require File.expand_path('../lib/persistent-cache/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ernst van Graan"]
  gem.email         = ["ernst.van.graan@hetzner.co.za"]
  gem.description   = %q{Persistent Cache limited to STORAGE_RAM}
  gem.summary       = %q{Persistent Cache limited to STORAGE_RAM}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "persistent-cache-ram"
  gem.require_paths = ["lib"]
  gem.version       = Persistent::Cache::VERSION
  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'byebug'
  gem.add_dependency 'eh'
end
