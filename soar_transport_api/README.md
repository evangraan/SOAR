# SoarTransportApi

This gem specifies the API to be implemented by transport providers that want to communicate across soar_comms communication fabric. The API allows for message identification, sending and receiving, both synchronously and asynchronously. Messages are simple Hash objects with formatting to be dictated by the transport provider and consumer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soar_transport_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install soar_transport_api

## Usage

### Building a provider

Extend SoarTransportAPI::TransportAPI and override the methods of interest. For example, for a synchronous HTTP transport provider:

```
  class HttpTransportApi < SoarTransportApi::TransportAPI
    attr_accessor :server
    @received

    def initialize(transport_identifier)
      super(transport_identifier)
      @@received = []
    end

    def send_message(uri, message)
      uri = URI.parse(uri)
      response = Net::HTTP.post_form(uri, {"message" => message})
      @@received.push(response)
      response
    end

    def receive_message
      message = @@received.pop
      message.body
    end  
  end
```

### Sending messages

Use the API as below to send messages both in the synchronous and asynchronous cases:

```
  message = { 'body' => 'This is a message' }
  provider = HttpTransportApi.new("http-example")
  provider.send_message("http://localhost:9393/postbox", message)
```

### Receiving messages

Use the API as below for receiving in the synchronous case while sending:

```
  response = provider.send_message("http://localhost:9393/postbox", message)
```

Alternatively after a send, in the synchronous case:
```
  response = provider.receive_message
```

Use the API as below for receiving in the asynchronous case. Provide the transport API registered
back to the subscriber in order for it to know which transport (it may have multiple) pinged it
with a message. We are using an AMQP transport provider for this example:

```
  class Subscriber
    def receive(message)
      puts "Received #{message}"
    end
  end

  class RabbitTransportProvider < SoarTransportApi::TransportAPI
    def receive_messages(callback, transport_provider_id)
      t = Thread.new {
        @conn.start
        ch   = @conn.create_channel
        q    = ch.queue(@transport_identifier)
        begin
          message = nil
          q.subscribe(:block => true) do |delivery_info, properties, body|
            puts " [x] Received message"
            callback.receive(transport_provider_id, body)
          end
          @conn.close
        rescue Interrupt => _
          @conn.close
        end
      }
      t.abort_on_exception = true    
    end
  end

  provider = RabbitTransportProvider.new("bunnies")
  subscriber = Subscriber.new
  provider.receive_messages(suscriber, "bunnies")
```

### Exceptions

The transport API raises the following exceptions:

```
  TransportIdentifierInvalidError - a transport identifier was not provided (nil) or was not a String or was an empty string
  SubscriberCallbackInvalidError - the subscriber specified for callbacks of received messages was not provided (nil) or does not have a receive method
  NoMessageError - No message was provided to send
  InvalidURIError - An invalid URI or no URI was provided
```

## Contributing

Bug reports and feature requests are welcome by email to ernst dot van dot graan at hetzner dot co dot za. This gem is sponsored by Hetzner (Pty) Ltd (http://hetzner.co.za)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

