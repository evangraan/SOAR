# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_idm/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_idm"
  spec.version       = SoarIDM::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{Generic implementation of a SOAR Identity management API}
  spec.description   = %q{Generic implementation of a SOAR Identity management API}
#  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
#  spec.required_ruby_version = ['>=2.0.0']

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
  spec.add_dependency "jsender"
end
