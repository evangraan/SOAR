require "converse/comms/simple_logger"

module Converse

  class Interaction
    attr_accessor :broker
    attr_accessor :concern
    attr_accessor :action
    attr_accessor :substance
    attr_accessor :conversation
    attr_accessor :should_i_ask

    private

    @validation

    public

    def discuss_with_broker_concerning(broker, concern)
      discuss_with(broker)
      concerning(concern)
      self
    end

    def ask_broker_concerning(broker, concern)
      ask_broker(broker)
      concerning(concern)
      self
    end

    def tell_broker_concerning(broker, concern)
      tell_broker(broker)
      concerning(concern)
      self
    end

    def ask_broker(broker)
      @broker = broker
      @should_i_ask = true
      self
    end

    def tell_broker(broker)
      @broker = broker
      @should_i_ask = false
      self
    end

    def discuss_with(broker)
      @broker = broker
      self
    end

    def concerning(concern)
      @concern = concern.dup
      self
    end

    def about(action)
      @action = action.dup
      self
    end

    def to(action)
      about(action)
    end

    def detailed_by(substance)
      @substance = substance
      self
    end

    def using(substance)
      detailed_by(substance)
    end

    def with(substance)
      detailed_by(substance)
    end

    def by_asking
      @should_i_ask = true
      self
    end

    def by_saying
      @should_i_ask = false
      self
    end

    def ask
      @conversation.ask
    end

    def say
      @conversation.say
    end

    def discuss
      @conversation = broker.broker_conversation(@broker.open_topic(@concern, @action))
      @conversation.subscribe(SimpleLogger.new)
      @should_i_ask ? response = ask : response = say
      if not success?(response)
        response = handle_error!(response)
        return nil if response.nil?
      end
      translated_response = broker.translate_response(response)
      interpret_conversation(translated_response)
    end

    def interpret_conversation(response)
      response
    end

    def success?(response)
      true
    end

    def handle_error!(response)
      response
    end

    def ensure_that(substance)
      @validation = substance
      self
    end

    def includes(keys)
      raise ArgumentError, "No arguments provided for this interaction and it requires #{keys}" if @validation.nil?

      if @validation.kind_of?(Hash)
        keys.each do |k|
          raise ArgumentError, "#{k} must be provided for this interaction" if not @validation.has_key?(k)
        end
      end
    end

    def does_not_include(keys)
      if @validation.kind_of?(Hash)
        keys.each do |k|
          raise ArgumentError, "#{key} is invalid for this interaction" if @validation.has_key?(k)
        end
      end
    end
  end
end