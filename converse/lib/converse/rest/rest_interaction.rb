require 'cgi'
require "converse/interaction"
require "json"

module Converse
  class RESTInteraction < Interaction
    def ask_broker_about(broker, action, substance)
      ask_broker_concerning(broker, "")
      about(action)
      detailed_by(substance)
    end

    def tell_broker_to(broker, action, substance)
      tell_broker_concerning(broker, "")
      about(action)
      detailed_by(substance)
    end

    def ask
      @conversation.ask(path_with_params(@conversation.path, @substance))
    end

    def say
      @conversation.say(@conversation.path, compile_params(@substance))
    end

    def compile_params(params)
      params.map {|k,v| CGI.escape(k.to_s)+'='+CGI.escape(v.to_s) }.join("&")
    end

    def path_with_params(path, params)
      return path if params.nil? or params.empty?
      path + "?" + compile_params(params)
    end

    def success?(response)
      test_value = "#{response.code}"
      return test_value == "200"
    end

    def interpret_conversation(response)
      return format_response(response.body)
    end

    def format_error(response)
      result = []
      result << response.code
      result << response.body
      return result
    end

    def format_response(response_body)
      response_body
    end

    def is_json
      begin
        JSON.parse(@validation)
        true
      rescue ::Exception
        raise ArgumentError, "#{@validation} is not in JSON format"
      end
    end
  end
end