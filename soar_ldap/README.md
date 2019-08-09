# SoarLdap

SoarLdap is a simplified LDAP client library allowing easy access to entries on LDAP servers, using LDAP protocol version 3, for use in the SOAR architecture. SoarLdap has an optional built-in cache, which reduces the requirement for connections to the LDAP server. Freshness of 0 disables the cache. Freshness is in seconds.

SoarLdap adheres to the SoarIdm::DirectoryProvider specification for directory providers.

The finder find_entity can be over-ridden to model specific search behaviour. By default, get_entity establishes a connection and calls find_entity, which searches the subtree for UUIDs matching the identifier specified, or for dn entries which include the identifier specified. By default the finder includes the following fields: 'objectClass', 'cn', 'dn', 'entryuuid', 'description' and returns only the first entry found. You might want to override find_entity to return an array if you expect multiple results.

SoarLdap will raise a SoarLdapError if it encounters unexpected or invalid configuration or state. get_entity returns an LDAP::Entry. connect returns an LDAP::Conn.

## Installation

Add this line to your application's Gemfile:

    gem 'soar_ldap'

You also need to ensure that you have provided an appropriate ldap, e.g. ruby-ldap or jruby-ldap and that the OS you deploy on has libldap2-dev installed.

And then execute:

    bundle

Or install it yourself as:

    gem install soar_ldap

## Usage
    spec.add_development_dependency 'soar_ldap'
    bundle exec irb

    require 'soar_ldap'
    configuration = { 'server' => 'my.server.com', 'port' => 389, 'node' => 'ou=people,dc=my,dc=server,dc=com', freshness => 0 }
    credentials = { 'username' => 'ldap-user', 'password' => 'ldap-password' }
    @soar_ldap = SoarLdap::LdapProvider.new(configuration)
    @soar_ldap.authenticate(credentials)
    puts "This LDAP Provider operates on #{@soar_ldap.uri}"
    @soar_ldap.connect if @soar_ldap.bootstrapped?
    # returns LDAP::Conn
    puts "Connected? #{@soar_ldap.connected?}"
    ldap_entry = @soar_ldap.get_entity('findme') if @soar_ldap.ready?
    # By default returs LDAP::Entry or nil. You define this behaviour in find_entity.

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

