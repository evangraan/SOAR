module SoarTransportApi
  class TransportAPI
    DELIVERY_PENDING = "Delivery pending" unless defined? DELIVERY_PENDING; DELIVERY_PENDING.freeze
    DELIVERY_REJECTED = "Rejected for delivery" unless defined? DELIVERY_REJECTED; DELIVERY_REJECTED.freeze
    DELIVERY_FAILURE = "Delivery failure" unless defined? DELIVERY_FAILURE; DELIVERY_FAILURE.freeze
    DELIVERY_SUCCESS = "Delivered successful" unless defined? DELIVERY_SUCCESS; DELIVERY_SUCCESS.freeze
    DELIVERY_TIMEOUT = "Delivery timeout" unless defined? DELIVERY_TIMEOUT; DELIVERY_TIMEOUT.freeze

    attr_accessor :transport_identifier

    def initialize(transport_identifier)
      raise SoarTransportApi::TransportIdentifierInvalidError.new("Invalid transport identifier") if invalid_transport_identifier?(transport_identifier)
      @transport_identifier = transport_identifier
    end

    def send_message(uri, message)
      raise SoarTransportApi::NoMessageError.new("No message provided") if message.nil?
      raise SoarTransportApi::InvalidURIError.new("Invalid URI") if invalid_uri?(uri)
    end

    def receive_messages(subscriber, transport_provider_id)
      raise SoarTransportApi::TransportIdentifierInvalidError.new("Invalid transport identifier") if invalid_transport_identifier?(transport_provider_id)
      raise SoarTransportApi::SubscriberCallbackInvalidError.new("Invalid subscriber") if invalid_subscriber?(subscriber)
    end

    def receive_message
    end

    private

    def invalid_uri?(uri)
      return true if uri.nil?
      not (uri =~ URI::DEFAULT_PARSER.regexp[:UNSAFE]).nil? 
    end

    def invalid_transport_identifier?(transport_identifier)
      transport_identifier.nil? or
      (not transport_identifier.is_a?(String)) or
      transport_identifier.strip == ""
    end

    def invalid_subscriber?(subscriber)
      subscriber.nil? or
      not subscriber.methods.include?(:receive)

    end
  end
end
