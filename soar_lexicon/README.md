# SoarLexicon

This middleware provides dynamic service component WADL lexicon and individal service ?wadl lexicon. If /lexicon is requested on a service component, this middleware compiles a WADL document describing all routes registered with the router meta object provided. If a specific service endpoint is requested, appended with ?wadl, this middleware compiles a WADL document describing that service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_lexicon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_lexicon

## Usage

Ensure that your rack env includes a 'lexicon' key that is configured with route descriptions of the following form:

```
lexicon = {
  '/route-path' => {
    'description' => 'Business question answered here',
    'service_name' => 'business_service',
    'path' => '/route-path',
    'method' => 'get',
    'params' => {
      'pattern' => {
        'required' => 'true', 'type' => 'string'
      }
    },
  }
}
```

If you are using SoarAspects, this can be accomplished so:

```
SoarAspects::Aspects::lexicon = lexicon
use SoarAspects::Aspects
```

Then, in your config.ru, place:

```
  use SoarLexicon::Lexicon
```

## Visualizing

SoarLexicon delivers a WADL XML document and delivers an expectation of a style-sheet for display in a browser to be located on the service component at the path /wadl/wadl.xsl

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

