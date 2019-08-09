module Converse
  class Conversation
    attr_accessor :uri
    attr_accessor :body
    attr_accessor :headers
    attr_accessor :connection
    attr_accessor :host
    attr_accessor :port
    attr_accessor :path
    attr_accessor :request
    attr_accessor :response
    attr_accessor :subscribers

    def initialize(uri)
      @uri = uri
      parsed = URI.parse(uri)
      @host = parsed.host
      @port = parsed.port
      @path = parsed.path
      @subscribers = []
    end

    def ask
      raise NotImplementedError.new
    end

    def say
      raise NotImplementedError.new
    end

    def subscribe(subscriber)
      @subscribers << subscriber
    end

    def notify_subscribers(data)
      @subscribers.each do |subscriber|
        subscriber.notify(data)
      end
    end
  end
end
