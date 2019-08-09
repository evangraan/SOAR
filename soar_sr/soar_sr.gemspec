# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_sr/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_sr"
  spec.version       = SoarSr::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{Implementation of the Hetzner Service Registry specification, backed by jUDDI}
  spec.description   = %q{Implementation of the Hetzner Service Registry specification, backed by jUDDI}
  spec.homepage      = "https://github.com/hetznerZA/soar_sr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
#  spec.required_ruby_version = ['>=2.0.0']

  spec.add_dependency "persistent-cache-ram", "~> 0.4.3"
  spec.add_dependency "jsender"
  spec.add_dependency "soar_xt"
  spec.add_dependency "soap4juddi", "~> 1.0.6"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'    
end
