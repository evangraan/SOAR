# SoarSmaak

This library offers Rack middle-ware for SMAAK communication. Requests are examined to determine whether the route the request is destined for requires message signing, or whether the request itself is a SMAAK request. If either are true, the SMAAK message is interpreted and verified. The message is decrypted if it was encrypted, and passed to the rack application stack unencrypted, only if the signature is verified. After processing by the application stack, responses are signed into SMAAK responses, and encrypted if the authorization message indicated it should be. Non-SMAAK messages are passed through to the application stack without interpretation or verification. SoarSmaak::Router will refuse requests with a 500 in the case of any failures.

## Dependencies

### SoarAspects::Aspects

In order for soar_smaak to obtain its configuration, auditor and signed routes from the rack environment, these need to be placed in the environment before this middleware is used. The SoarAspects::Aspects middleware accomplishes this: https://rubygems.org/gems/soar_aspects

### configuration : optional

A dictionary including a SMAAK public and private key identifying the service component in question, as well as an optional associations dictionary with the identity and public key and pre-shared key of associations that the SMAAK middleware should verify. If a configuration is not provided, SMAAK will be disabled. An example follows:

```
public_key: |
  -----BEGIN RSA PRIVATE KEY-----
  MIICIdfsAKCAgEAsfB2D/ZZKyDB7YuZBzD1JghlkjglfdgloskzseFs1qiVLXks3
  ...
  -----END RSA PUBLIC KEY-----
private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIJKgIBAAKCAgEAsfB2D/ZZKyDB7YuZBzD1Jgh5kiWqOLjtpBkzseFs1qiVLX/S
  ...
  -----END RSA PRIVATE KEY-----
associations:
  i-can.identify-this.server:
    public_key: |
      -----BEGIN RSA PUBLIC KEY-----
      MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyt2nPgdfE/Osc2HQ8ZT0
      -----END RSA PUBLIC KEY-----
    psk: 655U0Rw6Rk12
```

### signed_routes: optional

A dictionary of paths and an indication whether the route is signed. If no routes are signed, SMAAK requests will still be verified if detected. If signed routes are provided, SMAAK verification will be done and non-SMAAK requests will be refused on those routes. E.g.

```
  { "/secure-service" => true,
    "/another-service" => false }
```

### auditing: optional

An auditing provider that adheres to the API specified here: https://rubygems.org/gems/soar_auditor_api. If an auditing provider is not present, STDOUT will be used.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_smaak'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_smaak

## Usage

In your application builder, set SOAR aspects that SoarSmaak depend on:

```
SoarAspects::Aspects::configuration = config
SoarAspects::Aspects::signed_routes = router_meta.signed_routes
SoarAspects::Aspects::auditing = auditing
use SoarAspects::Aspects
```

Then add the SMAAK middleware router:

```
use SoarSmaak::Router
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

