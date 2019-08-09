# SoarPolicyAccessManager

This Access Manager adheres to SoarAm::AmApi. It is initialized with a soar_sr service registy client (https://rubygems.org/gems/soar_sr)

This access manager denies access for unauthenticated requests, that is, request that do not have request.session['user'] set. If set, this access manager then queries the service registry for meta regarding the service identifier in question.

If the service meta indicates no policy, the request is allowed. It the service meta indicates a policy, the policy service is asked, given the authenticated subject identifier, service identifier, resource identifier and request parameters, whether the request should be allowed. This access manager then allows / denies accordingly.

In the case of the service not found in the service registry, or a failure of any kind, the request is denied. In the interest of security, exceptions while authorizing will be swallowed by this access manager. Only the last exception message will be reported to STDERR.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_policy_access_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_policy_access_manager

## Usage

```
policy_am = SoarPolicyAccessManager::PolicyAccessManager.new(SoarSc::service_registry)
puts policy_am.authorize(service_identifier, resource_identifier, authentication_identifier, request)
```

This access manager can be used with the SoarAuthorization::Authorize middleware:

```
SoarAuthorization::Authorize::register_access_manager('/path', 'path-service', policy_am)

use SoarAuthorization::Authorize
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
