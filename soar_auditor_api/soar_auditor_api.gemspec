# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_auditor_api/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_auditor_api"
  spec.version       = SoarAuditorApi::VERSION
  spec.authors       = ["Barney de Villiers"]
  spec.email         = ["barney.de.villiers@hetzner.co.za"]

  spec.summary       = %q{SOAR auditor api}
  spec.description   = %q{SOAR auditor api from which auditor implementations will extend}
  spec.homepage      = "https://github.com/hetznerZA/soar_auditor_api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", "~> 9"

end
