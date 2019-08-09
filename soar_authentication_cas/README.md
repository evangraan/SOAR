# SoarAuthenticationCas

This library provides CAS configuration for soar_sc. It supports 'production' and 'development' rack environments, and looks in RACK_ENV['CAS_SERVER'] to find the CAS server URI

Calling SoarAuthenticationCas::configure(environment) returns a dictionary containing CAS configuration:

```ruby
  { :prefix => signon_prefix,
    :browsers_only => are_we_in_development,
    :ignore_certificate => are_we_in_development }
```

:prefix contains the CAS prefix to use, e.g. 'https://my_cas_server.com/cas'

:browser_only indicates whether CAS should be in effect for browser interactions only, and is true only if it finds itself in the development environment

:ignore_certificate indicates whether certificate validation should be disabled, and is true only if it finds itself in the development environment

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_authentication_cas'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_authentication_cas

## Usage

This gem is used in conjunction with the kh_signon CAS client gem, as follows:

```ruby
require 'kh_signon'

options = SoarAuthenticationCas::configure(environment)
stack.use KhSignon::RackMiddleware, options if options
```

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
