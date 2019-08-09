# SoarWadlValidation

Middleware that generates a WADL document describing incoming requests and validates the requests against the WADL.

The validator will return a 400 with jsend JSON fail structure detailing validation failure conditions if WADL validation of the request fails, and call the app provided in the case of successful validation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_wadl_validation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_wadl_validation

## Usage

Initialize SoarAspects::Aspects with the necessary lexicon, then include this middleware in your middleware stack:

```
SoarAspects::Aspects::lexicon = lexicon
```

Then, in your config.ru, place:

```
  use SoarWadlValidation::Validator
```

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

