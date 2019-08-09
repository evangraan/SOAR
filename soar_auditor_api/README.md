# SoarAuditorApi

This gem provides the auditor api for the SOAR architecture.

## State of the API

This API is still a work in progress but should be sufficient for most auditors

Future work:
* The API should support the reformating of timestamps to a standardized ISO8601 format.

## Installation

Add this line to your auditor Gemfile:

```ruby
gem 'soar_auditor_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_auditor_api

## Testing

Behavioural driven testing can be performed:

    $ bundle exec rspec -cfd spec/*

Sanity testing can be performed:

    $ cd sanity
    $ bundle install
    $ bundle exec ruby sanity.rb

## Usage

### Auditors that extend from the AuditorAPI

Extend from the AuditorAPI as follow

``` ruby
class MyAuditor < SoarAuditorApi::AuditorAPI
end
```

It is required that the auditors that extend from this API implement two methods: "audit" and "configuration_is_valid". The API will call these methods using inversion of control as follow:

The configuration_is_valid method provides the API with a way of ensuring that a configuration is valid for the auditor.
```ruby
def configuration_is_valid(configuration)
  return configuration.include?("something_needed")
end
```

The audit method will be called when the base API wants to publish an audit event after it has been formatted and filtered.
```ruby
def audit(data)
  puts data
end
```

The configuration is made available to the auditor through the @configuration attribute in the API class.
```ruby
def audit(data)
  puts @configuration["preprefix"] + data
end
```


### Auditing Providers that utilize the AuditorAPI as clients

Instantiate an auditor that extends the AuditorAPI:
```ruby
@iut = SanityAuditor.new
```

Configure the auditor with required parameters:
```ruby
configuration = { "preprefix" => "very important:" }
@iut.configure(configuration)
```

Set the desired audit level. Allowed levels (in increasing level of priority) are :debug, :info, :warn, :error and :fatal.  As an example only :warn, :error and :fatal audit events will be logged if you set the level to :warn.
```ruby
@iut.set_audit_level(:warn)
```

Use the auditing interfaces as follow. The API also supports appending as below, enabling support, e.g. for Rack::CommonLogger, etc.:
```ruby
@iut.info("This is info")
@iut.warn("Statistics show that dropped packets have increased to #{dropped}%")
@iut.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate")
@iut.fatal("Unable to perform action, too many dropped packets. Functional degradation.")
@iut << 'Rack::CommonLogger requires this'
```

Note that the APIs (debug/info/warn/error/fatal) accept any object as a parameter. The object will be serialized using the .to_s method and therefore the object must implement the .to_s method (or already be of a basic object type that has the .to_s method).
```ruby
some_debug_object = 123
@iut.debug(some_debug_object)
```

### Serializable classes

Class instances to be logged in the message field can be serialized by extending from the SoarAuditorApi::Serializable class.
Store the data in the @data attribute and implement the to_s method that calls the serialize method in the base class.

``` ruby
class TestSerializable < SoarAuditorApi::Serializable
  attr_accessor :data

  def to_s
    serialize
  end
end
```

## Detailed example

```ruby
require 'soar_auditor_api'
require 'byebug'

class SanityAuditor < SoarAuditorApi::AuditorAPI
  def configuration_is_valid(configuration)
    return configuration.include?("preprefix")
  end

  def audit(data)
    puts @configuration["preprefix"] + data
  end
end

class Main
  def test_sanity
    @iut = SanityAuditor.new
    configuration = { "preprefix" => "very important:" }
    @iut.configure(configuration)
    @iut.set_audit_level(:debug)

    some_debug_object = 123
    @iut.info("This is info")
    @iut.debug(some_debug_object)
    dropped = 95
    @iut.warn("Statistics show that dropped packets have increased to #{dropped}%")
    @iut.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate")
    @iut.fatal("Unable to perform action, too many dropped packets. Functional degradation.")
    @iut << 'Rack::CommonLogger requires this'
  end
end

main = Main.new
main.test_sanity
```

## Contributing

Bug reports and feature requests are welcome by email to barney dot de dot villiers at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## Notes

Though out of scope for the provider, auditors should take into account encoding, serialization, and other NFRs.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
