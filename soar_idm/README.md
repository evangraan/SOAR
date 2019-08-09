# SoarIDM

SoarIDM is a generic API for Identity Registries to adhere to when playing an active role in accomplishing Identity Management. It was designed for use in the SOAR architecture. Extend the IdmApi class with your own, and provide the needed IDM functionality.

An IDM can be given an entity identifier, and asked to enumerate the roles associated with the entity. When given an entity identifier and a role, the IDM can provide attributes configured for the entity when acting as that role.

# Features

All functionality of the identity registry requires an entity identifier (non-empty string). When requesting attributes for a role, the role is optional (non-empty string).

If an invalid, non-string or empty entity identifier is provided, nil is returned for get_roles().
If a valid entity identifier is provided, the roles for than entity are returned in a dictionary.

If an invalid, non-string or empty entity identifier is provided, nil is returned for get_attributes().
If a valid entity identifier is provided, but no role is provided, all attributes for the entity are returned.
If a valid entity identifier is provided, and a valid role is provided, all attributes associated with that role for the entity are returned, provided the entity has that role. If the entity does not have that role, nil is returned.

If an invalid, non-string or empty entity identifier is provided, nil is returned for get_identifiers().
If a valid entity identifier is provided, all identifiers known for the entity *by this identity registry* are returned.

For all functions, the entity identifier provided is used to look up the entity identity. The following errors may occur, and result in a SoarIdm::IdentityError being raised:

If a programmatic error results in identities looked up being nil:
- Error looking up identity for identifier entity_identifier

If more than one identity is found for the entity identifier:
- Multiple identities found for identifier entity_identifier

If no identities are found for the entity identifier:
- Identities not found for identifier entity_identifier

## Directory

This IDM specification recommends an API for a source of truth directory that provides the IDM with the necessary data to which to apply a rule set in pursuit of identifier / role / attribute mapping. Please see the SoarIdm::DirectoryProvider for more detail.

## Installation

Add this line to your application's Gemfile:

		gem 'soar_idm'

And then execute:

    bundle

Or install it yourself as:

    gem install soar_idm

## Usage (provider)

When providing your own identity registry, extend the SoarIDM::IdmApi class and implement the inversion of control methods. These methods will receive the identity you provide on lookup of the identifier in calculate_identifiers().

    def calculate_roles(identity)
      # use your source of truth to match roles to the identity
      []
    end

    def calculate_all_attributes(identity)
      # walk the identity tree for your source of truth and extract all attributes
      {}
    end

    def calculate_attributes(identity, role)
      # extract all attributes for the role from your source of truth, given the identity
      { role => {} }
    end 

    def calculate_identifiers(entity_identifier)
      # walk the identity in your source of truth and extract all identifiers
      [entity_identifier]
    end

    def calculate_identities(entity_identifier)
      # find the UUID in your source of truth for the identity. The base IDM API generates one. For a simplified, shallow registry (not recommended,) simply return the entity identifier. Note though that the SOAR IDMs guarantee global uniqueness for identity UUIDs!
      [SecureRandom.uuid]
    end


Over-ride the public and private methods at your own risk and at the risk of non-compliance with the SOAR architecture.

## Usage (client)
	  spec.add_development_dependency 'soar_idm'
	  bundle exec irb
      require 'soar_idm/soar_idm'

In the examples that follow, @iut refers to 'implementation under test' a.k.a 'item under test'
Extend the {SoarIDM::IdmApi IDM API} class to create an identity registry.

Consumers of your identity registry will expect to use it so:

		entity_identifier = "entity identifier"
		entity_roles = @iut.get_roles(entity_identifier)
		# [ 'role1', 'role2']

		attributes = @iut.get_attributes(entity_identifier, role)
		# { 'role1' => {'attribute1' => 'value1', 'attribute2' => 'value2'}, 'role2' => {'attribute3' => 'value3', 'attribute4' => 'value4'}}

        identifiers = @iut.get_identifiers(entity_identifier)
        # [ 'entity identifier', 'another identifier']

## Deploying

This identity management framework can be deployed in-process in any ruby application or application server. It was intended as a library in support of identity registries as SOA services in the SOAR architecture, to be deployed on soar_sc service components.

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
