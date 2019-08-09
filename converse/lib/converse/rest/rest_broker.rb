require "converse/broker"

module Converse
  class RESTBroker < Broker
    attr_accessor :host
    attr_accessor :port
    attr_accessor :username
    attr_accessor :password

    def broker_conversation(topic)
      conversation = HTMLConversation.new(topic)
      conversation.username = @username if @username.nil? == false
      conversation.password = @password if @password.nil? == false
      conversation
    end

    def open_topic(concern, action)
      if (concern.nil? == true or concern == "")
        "http://#{host_and_port()}/#{action}"
      else
        "http://#{host_and_port()}/#{concern}/#{action}"
      end
    end

    def host_and_port
      u = ""
      u = u + "#{@host}" if not @host.nil?
      u = u + ":#{@port}" if not @port.nil?
      u
    end

    def authenticated_by(username)
      @username = username
      self
    end

    def with_password(password)
      @password = password
      self
    end

    def talks_to(host)
      @host = host
      self
    end

    def on_port(port)
      @port = port
      self
    end
  end
end