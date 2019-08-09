# SoarScViews

This library contains a collection of soar_sc views and view loaders. Views and loaders are provided in the SoarSc::Web::Views namespace.

Views must provide the following API:

```ruby
module SoarSc
  module Web
    module Views
      module TheView
        def self.render(http_code, body)
          [http_code, {"Content-Type" => "content-type-here"}, [body]]
        end

        def self.not_found
          [404, {}, ["404 - Not found"]]
        end

        def self.not_authenticated
          [401, {}, ["401 - Not authenticated"]]
        end

        def self.not_authorized
          [403, {}, [" 403 - Not authorized"]]
        end

        def self.not_valid(errors)
          [400, {"Content-Type" => "content-type-here"} , errors]
        end

        def self.error(ex)
          body = exception_handling
          [500, {"Content-Type" => "content-type-here"}, [body]]
        end
      end
    end
  end
end
```

Loaders must provide the following API:

```ruby
module SoarSc
  module Web
    module Views
      module TheLoader
        def self.load(view, data)
          render_the_view_with_the_data
        end
      end
    end
  end
end

```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_sc_views'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_sc_views

## Usage



## Contributing

Please send feedback and comments to the author at:

Ernst van Graan <ernst.van.graan@hetzner.co.za>

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

