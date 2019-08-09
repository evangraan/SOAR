# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jruby-ldap-fixes/version"

Gem::Specification.new do |s|
  s.name        = "jruby-ldap-fixes"
  s.version     = JRuby::LDAP::VERSION
  s.authors     = ["Ernst van Graan"]
  s.email       = ["ernst.vangraan@gmail.com"]
  s.homepage    = "http://jruby-extras.rubyforge.org/jruby-ldap"
  s.summary     = "Port of Ruby/LDAP to JRuby with fixes"
  s.description = "Fixes applied to jruby-ldap which has been stale for years"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
