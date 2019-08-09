# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_sc_core/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_sc_core"
  spec.version       = SoarScCore::VERSION
  spec.authors       = ["Ernst Van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{Service component core aggregations}
  spec.description   = %q{Service component core aggregations for simple inclusion into service components}
  spec.homepage      = "https://github.com/hetznerZA/soar_sc_core"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # web services
  spec.add_dependency "haml", "~> 4.0.7"
  spec.add_dependency 'wadling', "~> 0.1.9"
  spec.add_dependency 'soar_sc_mvc', "~> 0.2.0"
  spec.add_dependency 'soar_sc_views', "~> 0.1.2"
  spec.add_dependency "soar_lexicon", "~> 0.1.3"
  spec.add_dependency 'soar_configured_factory', '~> 0.1.0'
  spec.add_dependency 'soar_sc_routing', "0.3.0"

  # API
  spec.add_dependency 'jsender', "~> 0.2.2"
  spec.add_dependency "soar_flow", "~> 0.1.1"
  spec.add_dependency "soar_wadl_validation", "~> 0.1.3"

  # Bootstrap
  spec.add_dependency "soar_aspects", "~> 0.1.2"
  spec.add_dependency "soar_environment", "~> 0.2.0"
  spec.add_dependency "soar_configuration", "~> 0.2.0"
  spec.add_dependency "soar-dependency_container", "~> 0.2.0"

  # Identity management
  spec.add_dependency "soar_authentication", "~>0.1.3"
  spec.add_dependency "soar_authentication_cas", "~> 0.1.2"
  spec.add_dependency "soar_authentication_token", "~>7.1.0"
  spec.add_dependency "soar_authorization", "0.1.7"
  spec.add_dependency 'smaak', "~> 0.2.2"
  spec.add_dependency 'soar_smaak', "~> 0.1.19"
  spec.add_dependency 'soar_pl', "~> 0.0.12"
  spec.add_dependency 'soar_idm', "~> 0.0.2"
  spec.add_dependency 'idr_client', "~> 0.0.3"

  # Auditing
  spec.add_dependency "soar_auditing_provider", "~> 3.0.0"
  spec.add_dependency "logstash_auditor", "~> 1.1.1"
  spec.add_dependency "log4r_auditor", "~> 1.1.0"

  # Integration
  spec.add_dependency 'soar_sr', "~> 1.1.25"
  spec.add_dependency 'workflow', "~> 1.2.0"

  # Misc
  spec.add_dependency "soar_analytics", "~> 0.0.1"
  spec.add_dependency 'soar_status', "~> 0.1.0"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", '~> 10'
end
