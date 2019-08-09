# SoarAuthentication

This middleware will refuse unauthenticated requests. Refusal means a 401 response code with a message indicating authentication failure. Requests are unauthenticaed if request.session['user'] is not set. Your authentication strategy can authenticate the request by setting request.session['user']. If ENV['RACK_ENV'] == 'development', authentication will always be approved. The SoarAuthentication::Authentication class can interpret a request, tell if its authenticated and which identifier was used. If ENV['RACK_ENV'] == 'development' asking for the identifier will yield 'developer'

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_authentication'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_authentication

## Usage

```
use SoarAuthentication::Authenticate
```

To use the helper Authentication class:

```
  iut = SoarAuthentication::Authentication.new(request)
  iut.authenticated?
  puts iut.identifier
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

