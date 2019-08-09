module Converse
  class Broker
    attr_accessor :domain_language

    def open_topic(concern, action)
    end

    def broker_conversation(topic)
    end

    def translate_response(response)
      response
    end

    def discuss(concern, action)
      broker_conversation(open_topic(concern, action))
    end
  end
end
