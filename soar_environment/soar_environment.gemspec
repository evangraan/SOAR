# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soar_environment/version'

Gem::Specification.new do |spec|
  spec.name          = "soar_environment"
  spec.version       = SoarEnvironment::VERSION
  spec.authors       = ["Ernst Van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{This library determines the set of environment variables for a service component in the SOAR architecture}
  spec.description   = %q{This library determines the set of environment variables for a service component in the SOAR architecture}
  spec.homepage      = "https://github.com/hetznerZA/soar_environment"
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

  spec.add_dependency "psych", "~> 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'

end
