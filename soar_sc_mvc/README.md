# SoarScMvc

This library includes a configured controller, configured model and model factory supporting the SOAR reference implementation service component MVC. ConfiguredController provides access to soar_sc dependencies as and requesty body, as well as a configured and ready-to-use SMAAK client.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_sc_mvc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_sc_mvc

## Usage

### SoarSc::Web::Models::ModelFactory

Given a configuration with a provider adhering to SoarSc::Web::Models::ConfiguredModel, configured as follows:

```ruby
{ 'providers' => 
  { 'my_provider' => 
    { 'adaptor' => 'MyAdaptorClass',
      'some' => 'value' }
  }
}
```

an instance of the model (MyAdaptorClass), readily configured with the configuration hierarchy

```ruby
{ 'some' => 'value' }
```

can be obtained so:

```ruby
model_factory = SoarSc::Web::Models::ModelFactory.new(configuration)
model = model_factory.create('my_provider')
```

### ConfiguredModel

```ruby
class MyModel < SoarSc::Web::Models::ConfiguredModel
end

model = MyModel.new(configuration)
puts model.configuration
```

### ConfiguredController

class MyController < SoarSc::Web::Controllers::ConfiguredController
  def serve(request)
    puts "Dependencies are: #{dependencies}"
    puts "body is #{body(requests)}"
    puts "I can use smaak client #{smaak_client}"
    [200, "100"]
  end
end

controller = MyController.new(configuration)

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

