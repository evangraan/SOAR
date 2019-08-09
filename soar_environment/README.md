# SoarEnvironment

This library provides environment discovery functionality for the SOAR architecture and includes obtaining variables from the environment, and supplementing with an environment YAML file. When RUBY_PLATFORM is 'java', system properties are used instead of ENV. Once loaded, the configuration can be supplemented with values for keys in SOAR_CONFIGURATION_KEYS supplied in a configuration provided.

Exceptions raised:
- ArgumentError when RACK_ENV is not set in the process environment nor environment file
- ArgumentError when a configuration is not provided or is not a Hash when supplementing environment with configuration
- SoarEnvironment::LoadError when an environment file does not exist when loading environment
- SoarEnvironment::LoadError when an environment file cannot be loaded when loading environment

Once an environment is loaded (taking process and environment file into account), supplementing from configuration can be performed. Supplementing only provides values if the keys are not already present in the environment, thus if present in an environment file, that entry would be preferred above presence in configuration.

This library also provides an environment validator that expects an IDENTIFIER and RACK_ENV to be set to one of SoarEnvironment::EnvironmentValidator::VALID_EXECUTION_ENVIRONMENTS
 
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar-environment'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar-environment

## Usage

```
@iut = SoarEnvironment::Environment.new
environment = @iut.load_environment

@iut = SoarEnvironment::Environment.new(@environment_file_path)
environment = @iut.load_environment
```

Once loaded, the environment can be supplemented with a configuration:

```
environment = @iut.supplement_with_configuration(config)
```

An environment can be validated:

```
validator = SoarEnvironment::EnvironmentValidator.new
errors = validator.validate(environment)
# => [ invalid service identifier', 'Missing execution environment indicator', 'Invalid execution environment indicator' ]
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

