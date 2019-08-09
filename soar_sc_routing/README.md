# SoarScRouting

## Features

### RouterMeta
This library facilitates the registration of routes and their meta for use by a router. The SOAR reference implementation uses this library to register routes and meta for soar_sc routers.

When a route is registered, control is delegated as appropriate to the controller, renderer and access manager indicated in the meta.

An IoC function is provided that specialization classes can use to group registrations in during initialization of the router meta instance.

An IoC function is provided to delegate rendering of views to the specialized class.

### BaseRouter

This library also provides a base router to build routers from. The router will search all paths registered with it and call  the block registered for the first matched path.

The block delegates to the controller specified in the meta, and then renders the ouput using the renderer (view) specified in the meta.

The base router also provides two IoC functions to cater for routes not found and exceptions while routing.

### Router meta

Router meta is validated during registration and takes the form:

```ruby
{ 'description' => 'description',
  'service_name' => 'service_name',
  'method' => 'GET/POST/...',
  'path' => '/path',
  'params' => { 'para' => 'm1'},
  'nfrs' => { 'secured' => 'SIGNED/UNSIGNED',
              'authorization' => 'AUTHORIZED/UNAUTHORIZED'
            }
}
```

If a route is marked as AUTHORIZED, the route and the access manager set are registered with SoarAuthorization::Authorize.

The interpretation of a route marked as SIGNED is left up to the router implementation. In soar_sc SIGNED activates and requires SMAAK for requests traversing the route.

###Validation errors:

```ruby
ArgumentError "detail must not be nil" if the detail parameter is nil
ArgumentError "path must be provided" if detail['path'] is nil
ArgumentError "description must be provided" if detail['description']
ArgumentError "service_name must be provided" if detail['service_name']
ArgumentError "method must be provided" if detail['method'] is nil
ArgumentError "nfrs must be provided" if detail['nfrs']
ArgumentError "nfrs['authorization'] must be provided" if detail['nfrs']['authorization'] is nil
ArgumentError "nfrs['secured'] must be provided" if detail['nfrs']['secured'] is nil
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_sc_routing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_sc_routing

## Usage

### RouterMeta

```ruby
class AuthenticatedRouterMeta < SoarScRouting::RouterMeta
  def access_manager
    provider = Soar::Authorization::AccessManager::Provider::ServiceRegistry.new(SoarSc::service_registry)
    @policy_am ||= Soar::Authorization::AccessManager.new(provider)
    @policy_am
  end

  def setup_routing_table
    # register_route({
    #   'description' => 'Given a pattern, finds services matching the pattern and reports where they can be accessed',
    #   'service_name' => 'where-is-it',
    #   'path' => '/where-is-it',
    #   'method' => 'get',
    #   'params' => {
    #     'pattern' => {
    #       'required' => 'true', 'type' => 'string'
    #     }
    #   },
    #   'nfrs' => {
    #     'authorization' => 'AUTHORIZED',
    #     'secured' => 'UNSIGNED'
    #   },
    #   'view' => {
    #     'renderer' => 'json',
    #     'name' => 'where_is_it'
    #   },
    #   'controller' => 'WhereIsIt'
    # }, SoarSc::startup_flow_id)
  end

  def render_view(detail, http_code, body)
    renderer = SoarSc::Renderer.new
    renderer.render_view(detail, http_code, body)
  end
end
```

### BaseRouter

```ruby
class SoarScRouter < SoarScRouting::BaseRouter
  def not_found
    SoarSc::Web::Views::Default.not_found
  end

  def excepted(ex)
   SoarSc::Web::Views::Default.error(ex)      
  end
end
```

## Testing

Testing can be performed:

    $ bundle exec rspec -cfd spec/*

## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
