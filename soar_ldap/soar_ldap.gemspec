# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_ldap/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_ldap"
  spec.version       = SoarLdap::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{LDAP client library allowing easy acces to entries on LDAP servers}
  spec.description   = %q{LDAP client library allowing easy acces to entries on LDAP servers}
#  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
#  spec.required_ruby_version = ['>=2.0.0']

  spec.add_dependency "persistent-cache-ram"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_dependency "soar_idm"
end
