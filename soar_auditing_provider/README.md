# SoarAuditingProvider

[![Gem Version](https://badge.fury.io/rb/soar_auditing_provider.png)](https://badge.fury.io/rb/soar_auditing_provider)

This gem provides an auditing provider for the SOAR architecture.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_auditing_provider'
```

Note that the auditing provider will only be useful when configured with an auditor that extends from soar_auditor_api. Recommend using log4r_auditor for auditing to a local file and standard stream. Alternatively use logstash_auditor for auditing to a centralized system.

```ruby
gem 'log4r_auditor'
```
and/or
```ruby
gem 'logstash_auditor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_auditing_provider


## Testing

Run the rspec test tests:

    $ bundle exec rspec -cfd spec


## Usage

Require the gems responsible for various aspects of the auditing
```ruby
require 'soar_auditing_provider'
require 'log4r_auditor'
require 'soar_flow'
```

Initialize and configure the provider.
```ruby
AUDITING_CONFIGURATION = {
  'auditing' => {
    'level' => 'info',
    'queue_worker' => {
      'queue_size' => 1000,
      'initial_back_off_in_seconds' => 1,
      'back_off_multiplier' => 2,
      'back_off_attempts' => 5
    },
    'default_nfrs' => {
      'accessibility' => 'local',
      'privacy' => 'not encrypted',
      'reliability' => 'instance',
      'performance' => 'high'
    },
    'auditors' => {
      'log4r' => {
        'adaptor' => 'Log4rAuditor::Log4rAuditor',
        'file_name' => 'soar_sc.log',
        'standard_stream' => 'stdout',
        'nfrs' => {
          'accessibility' => 'local',
          'privacy' => 'not encrypted',
          'reliability' => 'instance',
          'performance' => 'high'
        }
      }
    }
  }
}
myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'] )
```

In order to associate all startup and shutdown related audit events with each other it is useful to set an instance flow identifier. Generate an unique flow identifier and pass to the auditing provider.  Optional but very useful.
```ruby
myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
```

When auditing to a local file there is no need to identify each audit event with a specific service since each service probably has its own audit file.  However, when merging audit events to a centralized system it is vital to associate each audit event with a specific service and instance thereof.  Set an unique service identifer that will form part of each audit event as follow:
```ruby
myauditing.service_identifier = 'my-test-service.com'
```

Configure the audit level of the auditing provider either inside the configuration or by calling the set_audit_level method. This will result in audit events of a lower level being ignored.
```ruby
myauditing.set_audit_level(:info)
```

Generate audit events by passing in anything that implements the to_s method. The set and order of audit levels are [debug,info,warn,error,fatal]. Note that passing in the flow identifier is optional but recommended for each audit event.
```ruby
some_debug_object = 123
myauditing.info("This is info",flow_id)
myauditing.debug(some_debug_object,flow_id)
dropped = 95
myauditing.warn("Statistics show that dropped packets have increased to #{dropped}%",flow_id)
myauditing.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate",flow_id)
myauditing.fatal("Unable to perform action, too many dropped packets. Functional degradation.",flow_id)
myauditing << 'Rack::CommonLogger requires this'
```

## Detailed example

```ruby
require 'soar_auditing_provider'
require 'log4r_auditor'
require 'soar_flow'

class Main

  AUDITING_CONFIGURATION = {
    'auditing' => {
      'level' => 'debug',
      'install_exit_handler' => 'true',
      'add_caller_source_location' => 'false',
      'queue_worker' => {
        'queue_size' => 1000,
        'initial_back_off_in_seconds' => 1,
        'back_off_multiplier' => 2,
        'back_off_attempts' => 5
      },
      'default_nfrs' => {
        'accessibility' => 'local',
        'privacy' => 'not encrypted',
        'reliability' => 'instance',
        'performance' => 'high'
      },
      'auditors' => {
        'log4r' => {
          'adaptor' => 'Log4rAuditor::Log4rAuditor',
          'file_name' => 'soar_sc.log',
          'standard_stream' => 'stdout',
          'nfrs' => {
            'accessibility' => 'local',
            'privacy' => 'not encrypted',
            'reliability' => 'instance',
            'performance' => 'high'
          }
        }
      }
    }
  }

  def test_sanity
    #create and configure auditing instance
    myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'] )
    myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
    myauditing.service_identifier = 'my-test-service.com'

    #associate a set of auditing entries with a flow by generating a flow identifiers
    flow_id = SoarFlow::ID::generate_flow_id

    #generate audit events
    some_debug_object = 123
    myauditing.info("This is info",flow_id)
    myauditing.debug(some_debug_object,flow_id)
    dropped = 95
    myauditing.warn("Statistics show that dropped packets have increased to #{dropped}%",flow_id)
    myauditing.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate",flow_id)
    myauditing.fatal("Unable to perform action, too many dropped packets. Functional degradation.",flow_id)
    myauditing << 'Rack::CommonLogger requires this'
  end
end

main = Main.new
main.test_sanity
```

## Out of Band Auditing

In order prevent auditing from affecting normal execution the audit events are buffered and published to the auditor using a separate thread.  

The buffer size can be configured.  When full, new entries are discarded in favor of old entries and the overflow counter incremented. The separate thread will use the auditor to publish the buffered audit events in order irrespective of level.  Failures are retried using a configurable exponential back off scheme.

## At_exit Hook

The auditing provider automatically chains a hook into the Kernel at_exit method in order to flush the audit entries at shutdown. It will generate a final audit entry (info level) stating "Application exit" with the flow identifier set using the instance_flow_id= method. Thereafter it attempts to flush the remaining entries to the selected auditor.  Failing that, it will flush the entries to the standard error stream and exit.

## Status

Provision has been made for out-of-band status/statistics gathering inside the auditing provider.  The hash containing the status/statistics is accessible using the status method call:
```ruby
myauditing.detailed_status
```

At present only the buffer overflow count is avialable:
```ruby
  { 'audit_buffer_overflows' => 123 }
```

## Testing

Behavioural driven testing can be performed by testing so:

    $ bundle exec rspec -cfd spec/*

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## Notes

Though out of scope for the provider, auditors should take into account encoding, serialization, and other NFRs.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
