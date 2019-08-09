# Converse

Converse is an architectural / design tool that facilitates dependency inversion, separation of concerns and decoupling
by providing a conversation-based API boundary.

Brokers know how to talk the language of a provider, and converses with such a provider using Interactions.
Interactions discuss topics using technology specific conversations. Brokers speak two languages: the application's and
a provider's. A broker is taught how to speak a provider's language by defining a set of interactions, which
use provider-specific conversations to communicate. Responses from providers are processed / translated in the
interactions. Formatting of responses and error handling are also processed in the interactions.
Each interaction can interpret a response in a provider-specific way and translate the response into the
application's domain language.

An application then relies on brokers to engage providers around topics, concerns and actions, by saying or asking and
receiving the interpreted responses.

Modeling API interaction this way decouples the application from the providers. The brokers are in essence adapters
that allow the creation of an application-specified API for interacting with providers, removing the application's
dependency on providers. The application only depends on the API it specifies, i.e. the language it wants to talk.

Brokers become plug-in adapters to providers and can be swapped out at will, provided they can speak the application's
language as well as the provider's language. The set of interactions a broker is aware of specifies the API towards
the provider. The application specifies its API through a set of methods that ask brokers to act on its behalf.

Brokers can be chained for multiple translation / technology bridging.

Brokers and conversations supplied with the gem: HTML, REST, MySQL
Brokers and conversations planned for future release: MCollective, Redis, ActiveMQ

This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## Installation

Add this line to your application's Gemfile:

    gem 'converse'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install converse

## Usage

In this example, a provider communicates RESTfully over HTTP. An application wants to talk with the provider,
without engaging in the details of setting up an HTML conversation, and without specifying URL details. Specifically,
the application wants to request a list of transactions from the RESTful transaction provider. The application might
want to swap the RESTful provider out for a SQL provider, or some other provider at some stage.

The application specifies the API it wants to talk, and teaches a broker how to discuss transactions:

    class ApplicationApi < Converse::API
      def get_transactions(client_id)
        substance = { :client_id => client_id }
        o = GetTransactions.new(@broker, substance)
        o.discuss
      end
    end

The GetTransactions interaction faces towards the provider, and uses a TransactionTranslator to turn JSON responses
into a list of transactions that the application understands.

    class GetTransactions < Converse::Interaction
      def initialize(broker, substance)
        ensure_that(substance).includes [:client_id]
        ask_broker(broker).concerning("transactions").about("<client_id>/transactions.json").detailed_by(substance)
      end

      def interpret_conversation(response)
        return [] if response.code == '404'
        TransactionTranslator::build_financial_entries_from(response)
      end
    end

Generically, the provider interaction knows how to say and ask the provider for information:

    class ProviderInteraction  < Interaction
      def ask
        @conversation.ask(broker.prepare_content(@concern, @action), broker.generate_parameters(@substance))
      end

      def say
        @conversation.say(broker.prepare_content(@concern, @action), broker.generate_parameters(@substance))
      end
    end

The RESTInteraction class provides some additional interpretation of responses. Interactions can rely on the
RESTInteraction to call handle_error if "200 OK" is not received, and a formatting hook is provided:

    class GetRevisions < Converse::RESTInteraction
      def initialize(broker, substance)
        ensure_that(substance).includes [:server]
        ask_broker(broker).concerning("get_revision_list").about(substance)
      end

      def format_response(response_body)
        RevisionFormatter::format_revisions_for_html(JSON.parse(response_body))
      end

      def handle_error!(response)
        raise RuntimeError.new "#{response.code}, #{response.body}"
      end
    end

The ProviderBroker is taught how to talk the provider's language by using an HTMLConversation (or a technology specific
conversation, e.g. SQL, Redis, etc.). The broker provides the mapping of concerns, actions and detail (substance) to the
technology / domain specific format:

    class ProviderBroker < Broker
      attr_accessor :host
      attr_accessor :port
      attr_accessor :username
      attr_accessor :password

      def initialize(host, port , username, password)
        @version = "v1"
        @host = host
        @port = port
        @username = username
        @password = password
      end

      def broker_conversation(topic)
        conversation = HTMLConversation.new(topic)
        conversation.username = @username
        conversation.password = @password
        conversation
      end

      def open_topic(concern, action)
        "https://#{@host}:#{@port}/" + concern + "/" + action
      end

      def prepare_content(concern, action)
        "/" + concern + "/" + action;
      end
    end

The application, a dependency injector or a factory at some point decides to use the ProviderBroker to facilitate
interaction with the provider:

    broker = ProviderBroker.new(@host, @port, @username, @password)
    api = ApplicationApi.new(broker)
    api.get_transactions('C0000001')


## Contributing

1. Please send me feedback by email (ernst.van.graan@hetzner.co.za) on this project and ideas around improving the architectural facilities
provided by this gem.
