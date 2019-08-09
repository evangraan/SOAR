# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persistent-cache/version'

Gem::Specification.new do |spec|
  spec.name          = "persistent-cache-storage-api"
  spec.version       = Persistent::Storage::VERSION
  spec.authors       = ["Ernst Van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{This gem encodes the API that Persistent::Cache providers adhere to in order to plug in as a back-end provider.}
  spec.description   = %q{This gem encodes the API that Persistent::Cache providers adhere to in order to plug in as a back-end provider.}
  spec.homepage      = "https://github.com/evangraan/persistent-cache-storage-api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'byebug'  
end
