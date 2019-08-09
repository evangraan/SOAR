module SoarSmaak
  class Router
    attr_reader :configuration

    def initialize(app)
      @app = app
    end

    def smaak(request)
      @auditing.debug("Smaak: verifying request")
      auth_message, body = @server.verify_signed_request(request)
      @auditing.debug("Smaak: auth_message: #{auth_message}")
      return auth_message, body
    end

    def call(env)
      @configuration = env['configuration']
      @auditing = env['auditing']
      @signed_routes = env['signed_routes']
      SoarSmaak::SecureService::auditing = @auditing
      secure_service = SoarSmaak::SecureService.get_instance(@configuration)
      @server = secure_service.smaak_server
      @auditing.debug("Smaak: signed routes are: #{@signed_routes}")
      request = Rack::Request.new(env)
      if SoarSmaak::Interpreter::smaak_request?(request) or @signed_routes[request.path]
        @auditing.debug("Smaak: routing smaak request")
        begin
          auth_message, body = smaak(request)
        rescue => ex
          return [500, {"Content-Type" => "text/html"}, ['Unable to route request on SMAAK route. Was your request a SMAAK request?']]
        end
        return [403, {}, [" 403 - Not authorized"]] if not auth_message or not auth_message.identifier
        @auditing.debug("Smaak: request authorized for #{auth_message.identifier}")
        session = update_session_with_smaak(request, auth_message)
        env["rack.input"] = body
      else
        @auditing.debug("routing non-smaak request")
      end

      http_code, content_type, body = @app.call(env)

      if SoarSmaak::Interpreter::smaak_request?(request) or @signed_routes[request.path]
        @auditing.debug("Smaak: request authorized for #{auth_message.identifier}")
        return [http_code, content_type, [@server.compile_response(auth_message, body[0])]] if auth_message.encrypt
        return [http_code, content_type, @server.compile_response(auth_message, body)]
      else
        return http_code, content_type, body
      end
    # rescue => ex
    #   puts ex
    #   [500, {"Content-Type" => "text/html"}, ['Unable to route request on SMAAK route. Was your request a SMAAK request?']]
    end

    private

    def update_session_with_smaak(request, auth_message)
      session = request.session

      if session
        if session['user']
          session['route_info'] = auth_message.identifier
        else
          session['user'] = auth_message.identifier
        end
        return session
      else
        debug("No session?")
      end
    end

    def debug(message)
      if @auditing
        @auditing.debug(message)
      else
        $stderr.puts(message)
      end
    end
  end
end