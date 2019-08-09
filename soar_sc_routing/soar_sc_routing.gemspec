# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_sc_routing/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_sc_routing"
  spec.version       = SoarScRouting::VERSION
  spec.authors       = ["Ernst Van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{base router and router meta library for soar_sc}
  spec.description   = %q{base router and router meta library for soar_sc}
  spec.homepage      = "https://github.com/hetznerZA/soar_sc_routing"
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

  spec.add_dependency 'jsender', "~> 0.2.2"
  #spec.add_dependency 'smaak', "~> 0.2.2"
  spec.add_dependency "soar_aspects", "~> 0.1.2"
  spec.add_dependency 'soar_authorization', '~> 0.1.7'
  spec.add_dependency 'soar-authorization-access_manager', '~> 0.0.1'
end
