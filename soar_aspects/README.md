# SoarAspects

This library facilitates injection of SOAR aspects into the rack middleware env, making the aspects available to other middleware.

Aspects currently supported:
- configuration
- auditing
- route signatures

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_aspects'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_aspects

## Usage

```
SoarAspects::Aspects::config = @config
SoarAspects::Aspects::signed_routes = @signed_routes
SoarAspects::Aspects::auditing = @auditing
use SoarAspects::Aspects
```

### configuration

A configuration of interest to your middleware. In the SOAR architecture the configuration is a dictionary.

### signed_routes

SOAR routing middleware is interested in the meta of routes, such as security NFRs. signed_routes is a dictionary keyed by route path, and with a boolean value indicating whether the route should be signed. E.g.

```
{ '/secure' => true, '/unsecure' => false }
```

### auditing

SOAR uses auditors for logging and other reporting. auditing here is an object that adheres to https://rubygems.org/gems/soar_auditor_api

### lexicon

A lexicon of description and parameter, path and method definitions for a service. For the SOAR architecture, this looks so:

```
{
  '/route-path' => {
    'description' => 'Business question answered here',
    'service_name' => 'business_service',
    'path' => '/route-path',
    'method' => 'get',
    'params' => {
      'pattern' => {
        'required' => 'true', 'type' => 'string'
      }
    },
  }
}
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

