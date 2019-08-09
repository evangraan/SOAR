require 'net/http'
require "converse/comms/conversation"

module Converse
  class HTMLConversation < Conversation
    attr_accessor :use_ssl
    attr_accessor :username
    attr_accessor :password

    def initialize(uri)
      super(uri)
      @use_ssl = false
      @port = @use_ssl ? 443 : 80 if @port == nil
    end

    def notify_subscribers_of_request(path)
      output = "HTTP=>\n"
      output += "#{path}\n"
      output += "#{@request.body}\n"
      notify_subscribers(output)
    end

    def notify_subscribers_of_response
      output = "<=HTTP\n"
      output += "#{@response.body}\n"
      notify_subscribers(output)
    end

    def populate_request(path, data)
      @request.body = data if not data.nil?
      @request.basic_auth @username, @password if @username != nil or @password != nil
      notify_subscribers_of_request(path)
    end

    def converse(path, data = nil)
      populate_request(path, data)
      @response = connect.request @request
      notify_subscribers_of_response
      return @response
    end

    def connect
      if (@use_ssl)
        Net::HTTP.start(@host, @port, :use_ssl => @use_ssl ? "yes" : "no")
      else
        Net::HTTP.start(@host, @port)
      end
    end

    def ask(path = @path,  data = nil)
      @request = Net::HTTP::Get.new(path)
      converse(path, data)
    end

    def say(path = @path,  data = nil)
      @request = Net::HTTP::Post.new(path)
      converse(path, data)
    end
  end
end