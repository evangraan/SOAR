# SoarAuthorization

Middleware that matches resource requests with Access managers (potentially multiple for the same resource) and authorizes access to the resource, given the service identifier, resource identifier, list of access managers and request.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_authorization'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_authorization

## Usage

Register access managers adhering to the SoarAm::AmApi with the soar_authorization middleware. Multiple access managers can be registered on the same paths. Each in turn will be asked to authorize, until one fails or the request is approved.

```
SoarAuthorization::Authorize::register_access_manager(path, service_identifier, @access_manager)
```

In config.ru

```
use SoarAuthorization::Authorize
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).