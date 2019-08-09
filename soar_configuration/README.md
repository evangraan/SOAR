# SoarConfiguration

This library supports retrieving a configuration from a configuration server, given an environment that includes the configuration server details or from a YAML file using the filename provided.

The configuration is then validated by instantiating the class indicated using the 'validator' key. If such an entry does not exist, validation uses the default validator included in this library: 'SoarConfiguration::ConfigurationValidator'. The default validator ensures that the configuration is a dictionary.

## Errors

Errors are returned in an error array:

```ruby
config, errors = configuration.load_from_...
```

'invalid configuration' if the configuration is not a dictionary
'invalid configuration service URI' if an invalid configuration service URI was provided
'Could not load or parse configuration file. Is it YAML?' if the YAML file could not be parsed or loaded

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_configuration'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_configuration

## Usage

```ruby
configuration = SoarConfiguration::Configuration.new
config, errors = configuration.load_from_yaml("config/config.yml")
```

```ruby
configuration = SoarConfiguration::Configuration.new
config, errors = configuration.load_from_configuration_service(environment)
```

For details on the environment, see the [configuration_service] (https://rubygems.org/gems/configuration_service) and [configuration_service-provider-vault] (https://rubygems.org/gems/configuration_service-provider-vault) gems.

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

