# SoarScCore

This is the core SOAR service component library, aggregating SOAR libraries. Please see gemspec file for details. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_sc_core'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install soar_sc_core
```

## Usage

require 'soar_sc_core' and define a router. Also require your specific authentication technology. Then use the various SOAR middleware libraries as required. An example from soar_sc below:

```ruby
require 'soar_sc.rb'
require 'rack'
require 'rack/builder'
require 'bundler'
require 'kh_signon'

Bundler.require(:default)

SoarSc::configuration = SoarSc::load_environment_and_configuration
SoarSc::configuration = SoarSc::Providers::Auditing::bootstrap(SoarSc::configuration)
SoarSc::Providers::ServiceRegistry::bootstrap(SoarSc::configuration)
dependencies = SoarSc::inject_dependencies(SoarSc::configuration)
authenticated_meta = SoarSc::Web::AuthenticatedRouterMeta.new(SoarSc::configuration)
unauthenticated_meta = SoarSc::Web::UnauthenticatedRouterMeta.new(SoarSc::configuration)
lexicon = authenticated_meta.lexicon.merge(unauthenticated_meta.lexicon)
SoarSc::bootstrap_aspects(SoarSc::configuration, authenticated_meta, lexicon)

use SoarFlow::ID
use SoarAspects::Aspects
use SoarLexicon::Lexicon
use SoarWadlValidation::Validator

authenticated_router = SoarSc::SoarScRouter.new(authenticated_meta)
unauthenticated_router = SoarSc::SoarScRouter.new(unauthenticated_meta)

unauthenticated = Rack::Builder.new do
  use Rack::Static, SoarSc::static_options
  use Rack::ContentLength

  app = lambda do |env|
    request = Rack::Request.new(env)
    unauthenticated_router.route(request)
  end
  run app
end

authenticated = Rack::Builder.new  do
  SoarSc::bootstrap_sessions self
  SoarSc::bootstrap_authentication self
  use SoarAuthentication::Authenticate
  use SoarAuthorization::Authorize
  use Rack::Static, SoarSc::static_options
  use Rack::ContentLength
  use SoarSmaak::Router
  
  app = lambda do |env|
    request = Rack::Request.new(env)
    authenticated_router.route(request)
  end
  run app
end

SoarSc::auditing.info("Your launchpad is designated SoarSc #{SoarSc::VERSION}",SoarSc::startup_flow_id)

run Rack::Cascade.new([unauthenticated, authenticated])
```

## Testing

### Unit Tests
```bash
$ bundle exec rspec
```

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
