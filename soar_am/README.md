# SoarAm

SoarAm is a generic API for Access Managers to adhere to when playing an active role in accomplishing authorization. It was designed for use in the SOAR architecture. Extend the SoarAm class with your own, and provide the needed access manager functionality.

An access manager can be given a service_identifier, resource_identifier and request, and asked whether the subject identifier authenticated in the request is allowed to access the resource at the service identifier, given the context of the request.

SoarAm will extrace the authenticated subject identifier and refuse authorization if the request is not authenticated. If authenticated, the authorize IOC method is called to determine whether the request should be allowed given the context.

## Installation

Add this line to your application's Gemfile:

    gem 'soar_idm'

And then execute:

    bundle

Or install it yourself as:

    gem install soar_idm

## Usage (provider)

When providing your own access manager, extend the SoarAm::AmApi class and implement the authorize IOC method. SoarAm provides authorize with the authenticated identifier extracted from the Rack::Request

```
class MyAM < SoarAm::AmApi
  def authorize(service_identifier, resource_identifier, authentication_identifier, params)
    authentication_identifier != nil
  end
end
```

## Usage (client)

```
  auth = MyAm.new
  puts auth.authorized?('my-service', '/some/resource', request)
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
