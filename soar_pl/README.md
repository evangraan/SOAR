# SoarPl

[![Gem Version](https://badge.fury.io/rb/soar_pl.png)](https://badge.fury.io/rb/soar_pl)

SoarPl is a generic authorization policy implementation. It was designed for use in the SOAR architecture. Extend the AuthorizationPolicy class with your own, and provide the needed IDM interaction and rule set for interrogating subject_identifier, requestor_identifier, resource_identifier and request in order to make an authorization decision. The policy communicates the result using jsend.

The policy can be given a subject identifier, representing the subject to be authorized. Optionally, the resource identifier of the resource the subject wants to access can be supplied, as well as details of the request itself. Additionally, the identifier of the requestor asking the authorization question of the policy can also be supplied. This information in conjunction with the subject's roles and attributes as discovered from the (optional) IDM provided, form the full information set that the rule set can use to make the authorization decision.

## Installation

Add this line to your application's Gemfile:

		gem 'soar_pl'

And then execute:

    bundle

Or install it yourself as:

    gem install soar_pl

## Usage
	  spec.add_development_dependency 'soar_pl'
	  bundle exec irb

In the examples that follow, @iut refers to 'implementation under test' a.k.a 'item under test'
Extend the {SoarPl::AuthorizationPolicy AuthorizationPolicy} class to create a policy. Examples can be found here: https://github.hetzner.co.za/hetznerZA/soar_policies/tree/master/production

The implementation reaches out to the IDM provided and retrieves entity roles and attributes.
The IDM provided must adhere to the following API:

		subject_identifier = "string identifier"
		subject_roles = @idm.get_roles(subject_identifier)
		# [ 'role1', 'role2']
		attributes = {}
		attributes = @idm.get_attributes(subject_identifier, role)
		# { 'role1' => {'attribute1' => 'value1', 'attribute2' => 'value2'}, 'role2' => {'attribute3' => 'value3', 'attribute4' => 'value4'}}

Initialize your policy with an identifier and a configuration:

    @iut = MyRules.new('my-rules-policy', { 'clearance-threshold' => 7 })

The initialization may fail due to an error or validation failure (invalid parameters.) The initializer will always return a sane object though, on which you can call

    @iut.status

in order to see whether initialization succeeded. Status will be of the form:

    { 'dependencies' => 
      { 'configuration' => 'valid|invalid',
        'policy_identifier' => 'valid|invalid',
        'rule_set' => 'valid|invalid' } }

Optionally, require roles to be present for an entity that you identify with a subject identifier:

    @iut.requires_roles(['client', 'owner'])

If requiring roles, you must provide an IDM to retrieve the entity's roles, and the attributes for each role, from:

    @iut.use_idm(@idm_instance)

Check authorization for a subject identifier, (optionally) providing it with all your rule set (MyRules) needs to make the authorization decision:

    result = @iut.authorize(@subject_identifier, @requestor_identifier, @resource_identifier, @request)

The subject identifier (non-empty string) is required. The requestor identifier (non-empty string) and request details (in a format you specify, but must be a Hash) as well as the resource identifier (non-empty string) are optional.

The result is jsend of the form:

    { 'allowed' => true|false, 'detail' => 'a validation message', 'idm' => 'the IDM you specified or nil', 'rule_set' => 'the name of the rule set class' }

The result status will be 'fail' if something goes wrong, such as a validation failure. The status will be 'success' if the authorization took place, regardless of a true or false value for 'allowed'. 

When building your rule set, you can use your configuration as well as the parameters passed to the authorize method, and roles and attributes obtained from the IDM. You only have to override the apply_rule_set method as below. By the time apply_rule_set is called, you can rest assured that all required roles have been checked, if you specified an IDM. apply_rule_set must return a boolean indicator and a string message, e.g.:

    require 'soar_pl'

    class MyRules < SoarPl::AuthorizationPolicy
      def apply_rule_set(subject_identifier, requestor_identifier, resource_identifier, request, subject_roles, attributes)
        allow = attributes['client']['clearance'] > @configuration['clearance-threshold']
        message = allow ? 'Clearance level high enough' : 'Clearance level too low'
        return allow, message
      end
    end

IDM failures result in an Entity error being reported.

## Deploying

This authorization policy framework can be deployed in-process in any ruby application or application server. It was intended for deployment of authorization-as-a-service in the SOAR architecture and to be deployed on soar_sc service components.

When deployed as a service, policies should accept a required subject_identifier, an optional requestor_identifier, optional service_identifier and optional request. Policies that need the request to be present in making the policy decision, should be contacted using a secure medium.

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
