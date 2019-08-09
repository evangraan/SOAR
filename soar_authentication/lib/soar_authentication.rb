require "soar_authentication/version"
require "soar_authentication/authentication"

module SoarAuthentication
  class Authenticate
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      auth = SoarAuthentication::Authentication.new(request)
      return [401, {"Content-Type" => "text/html"}, ["401 - Not authenticated"]] if not auth.authenticated?

      @app.call(env)
    end
  end
end
