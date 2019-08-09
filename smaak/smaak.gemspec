# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smaak/version'

Gem::Specification.new do |spec|
  spec.name          = "smaak"
  spec.version       = Smaak::VERSION
  spec.authors       = ["Ernst van Graan"]
  spec.email         = ["ernstvangraan@gmail.com"]
  spec.description   = %q{Signed Message Authentication and Authorization with Key validation}
  spec.summary       = %q{This gems caters for both client and server side of a signed message interaction over HTTP or HTTPS implementing the RFC2617 Digest Access Authentication. The following compromises are protected against as specified: Man in the middle / snooping (HTTPS turned on), Replay (nonce + expires), Forgery (signature), Masquerading (recipient pub key check), Clear-text password compromise (MD5 pre-shared key)}
  spec.homepage      = "https://github.com/evangraan/smaak.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.0'

  spec.add_dependency "persistent-cache-ram", "~> 0.4.2"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.5.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'coveralls'
#  spec.add_development_dependency 'simplecov', "~> 0.11.1"
#  spec.add_development_dependency 'simplecov-rcov', "~> 0.2.3"
  spec.add_development_dependency 'rspec', "~> 3.4.0"
  spec.add_development_dependency 'rack', "~> 1.6.4"
end
