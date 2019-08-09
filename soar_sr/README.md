# SoarSr

[![Gem Version](https://badge.fury.io/rb/soar_sr.png)](https://badge.fury.io/rb/soar_sr)

SoarSr is a client library for accessing the features of a jUDDI registry. SoarSr translates jUDDI concepts into a SOA architectural view on UDDI storage. Services are concise singly responsible functional units. Service components are devices and application servers that offer services on a URI. Domain perspectives are functional grouping of services et al in pursuit of business goals. Teams are a kind of domain perspective. Services are described by wadl service definitions. Associating services or service components with domain perspectvice indicates functional association. Associating services or service components with teams indicate ownership. Domain perspectives (and so also teams) have one or more contacts associated.

This is accomplished by translating as follows:

Teams and Domain perspectives => jUDDI businesses
Service components and services => jUDDI services
Associations => ruby Hashes, url encoded in an entity's description

## Installation

Add this line to your application's Gemfile:

		gem 'soar_sr'

And then execute:

    bundle

Or install it yourself as:

    gem install soar_sr

## Usage
	  spec.add_development_dependency 'soar_sr'
	  bundle exec irb

### Helpers
	  require 'soar_sr'
	  credentials = { 'username' => 'uddi', 'password' => 'uddi' }

	  # Note: caching is pro-active, i.e. it will try and update once
	  # the entry half-life has been exceeded, at which point
	  # the entry freshness is reset. If update fails continuously or
	  # an update thread worker is not available to perform the update,
	  # or pro-active update is not triggered by a cache hit, once
	  # freshness is exceeded, the entry is forgotten and results in
	  # a new query to the registry on cache miss (potentially slow).
	  # Update worker threads have a concurrency upper limit of 10
	  freshness = 0 # > 0 to enable pro-active caching

	  @soar_sr = SoarSr::ServiceRegistry.new('http://localhost:8080', 'hetzner.co.za', 'hetzner', credentials, freshness)
	  ds = @soar_sr.domain_perspectives
	  sv = @soar_sr.services
	  sc = @soar_sr.service_components
	  sd = @soar_sr.service_definitions
	  ts = @soar_sr.teams
	  cc = @soar_sr.contacts
	  as = @soar_sr.associations
	  ss = @soar_sr.search

### Domain perspectives
	  ds.list_domain_perspectives
	  ds.register_domain_perspective('my domain')
	  ds.domain_perspective_registered?('my domain')
	  ds.domain_perspective_by_name('domains', 'my domain')
	  ds.deregister_domain_perspective('my domain')

### Services
	  sv.list_services
	  sv.register_service({'name' => 'my service', 'description' => 'a new service', 'definition' => 'http://de.finiti.on'})
	  sv.service_registered?('my service')
	  sv.configure_meta_for_service('my service', {'some' => 'meta'})
	  sv.meta_for_service('my service')
	  sv.add_service_uri('my service', 'http://one-uri.com/my_service')
	  sv.add_service_uri('my service', 'http://find-me-here.com/my_service')
	  sv.remove_uri_from_service('my service', 'http://one-uri.com/my_service')
	  sv.service_uris('my service')
	  sv.service_by_name('my service')
	  sv.deregister_service('my service')

### Service components
	  sc.list_service_components
	  sc.register_service_component('my sc')
	  sc.configure_service_component_uri('my sc', 'http://my-sc.com')
	  sc.service_component_registered?('my sc')
	  sc.service_component_uri('my sc')
	  sc.configure_meta_for_service_component('my sc', {'some' => 'meta'})
	  sc.meta_for_service_component('my sc')
	  sc.deregister_service_component('my sc') # This action can take up to a minute

### Service definitions
	  sd.register_service_definition('my service', 'http://github.com/myservice/def.wadl')
	  sd.service_definition_for_service('my service')
	  sd.deregister_service_definition('my service')

### Teams
    ts.list_teams
	  ts.register_team('my team')
	  ts.team_registered?('my team')
	  ts.deregister_team('my team')

### Contacts
	  contact = { 'name' => 'Peter Umpkin', 'email' => 'p.umpkin@ppatch.com', 'description' => 'Director of operations', 'phone' => '0917872413'}
	  contact2 = { 'name' => 'Bruce Atman', 'email' => 'b.atman@marvelling.com', 'description' => 'Head of sales'}
	  cc.add_contact_to_domain_perspective('my domain', contact)
	  cc.add_contact_to_domain_perspective('my domain', contact2)
	  cc.contact_details_for_domain_perspective('my domain')
	  cc.remove_contact_from_domain_perspective('my domain', contact)

### Associations
	  as.associate_service_component_with_domain_perspective('my sc', 'my domain')
	  as.service_component_has_domain_perspective_associations?('my sc')
	  as.associate_service_with_domain_perspective('my service', 'my domain')
    as.service_associations('my service')
	  as.domain_perspective_has_associations?('my domain')
	  as.domain_perspective_associations('my domain')
	  as.disassociate_service_component_from_domain_perspective('my domain', 'my sc')
	  as.disassociate_service_from_domain_perspective('my domain', 'my service')
	  as.delete_all_domain_perspective_associations('my domain')

### Search
	  #sv.register_service({'name' => 'search me', 'description' => 'pretty please', 'definition' => 'http://de.finiti.on'})
	  ss.search_for_service('search') # name
	  ss.search_for_service('please') # description
	  ss.search_for_service('ti.on')  # definition
	  ss.search_for_service_component('search') # name
	  ss.search_for_service_component('please') # description
	  ss.search_domain_perspective('my domain', 'search')
	  ss.search_access_points('one-uri.com')

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

