Gem::Specification.new do |s|
  s.name        = 'idr_client'
  s.version     = '0.0.3'
  s.date        = '2015-04-12'
  s.summary     = "Identity registry client"
  s.description = "Ruby client for communicating with Hetzner identity registries"
  s.authors     = ["Charles Mulder"]
  s.email       = 'charles.mulder@hetzner.co.za'
  s.files       = ["lib/idr_client.rb"]
  s.homepage    = 'http://rubygems.org/gems/hola'
  s.license       = 'MIT'
  s.add_runtime_dependency "soar_idm", "~> 0.0.2"
  s.add_development_dependency "rspec", "~> 3.3"
end
