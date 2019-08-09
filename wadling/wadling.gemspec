# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wadling/version'

Gem::Specification.new do |spec|
  spec.name          = "wadling"
  spec.version       = Wadling::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernstvangraan@gmail.com"]
  spec.description   = %q{Turns a list of services (REST resources) definitions into a WADL definition}
  spec.summary       = %q{Given a dictionary of resources with a description, input and output schemas, produces a WADL definition}
  spec.homepage      = "https://github.com/evangraan/wadling"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "11.2.2"
#  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'
  spec.add_development_dependency 'rspec', "~> 3.5.0"
end
