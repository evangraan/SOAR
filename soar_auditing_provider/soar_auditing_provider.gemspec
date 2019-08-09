# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_auditing_provider/version'

Gem::Specification.new do |spec|
  spec.name          = 'soar_auditing_provider'
  spec.version       = SoarAuditingProvider::VERSION
  spec.authors       = ['Ernst van Graan', 'Barney de Villiers']
  spec.email         = ['ernst.van.graan@hetzner.co.za', 'barney.de.villiers@hetzner.co.za']

  spec.summary       = %q{SOAR architecture auditing provider}
  spec.description   = %q{SOAR architecture auditing provider extending from auditing provider API}
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'byebug', '~> 9.0.5'
  spec.add_development_dependency 'log4r_auditor', '~> 1.1'
  spec.add_development_dependency 'soar_xt', '~> 0.0.3'

  spec.add_dependency 'soar_auditor_api', '~> 1.0'
  spec.add_dependency 'soar_auditing_format', '~> 0.0.5'
  spec.add_dependency 'soar_json_auditing_format', '~> 0.0.2'
  spec.add_dependency 'soar_flow', '~> 0.1.1'
  spec.add_dependency 'soar_thread_worker', '~> 0.2.0'
  spec.add_dependency 'soar_configured_factory', '~> 0.1.0'
end
