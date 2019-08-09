require "soar_authorization/version"
require 'soar_authentication'

module SoarAuthorization
  class Authorize
    attr_reader :app

    @@access_managers = {}

    def self.register_access_manager(path, service_identifier, access_manager)
      @@access_managers[path] ||= []
      @@access_managers[path] << { 'service_identifier' => service_identifier, 'access_manager' => access_manager } if not @@access_managers[path].include?(access_manager)
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      entries = @@access_managers[request.path]
      if entries
        entries.each do |entry|
          service_identifier = entry['service_identifier']
          access_manager = entry['access_manager']
          return [403, {"Content-Type" => "text/html"}, [" 403 - Not authorized"]] if not authorized?(env, access_manager, service_identifier, request.path, request)
        end
      end
      @app.call(env)
    end

    def authorized?(env, access_manager, service_identifier, path, request)
      return true if ENV['RACK_ENV'] == 'development'
      begin
        result = access_manager.authorized?({
          service_identifier: service_identifier, 
          resource_identifier: path, 
          request: {
            authentication_identifier: SoarAuthentication::Authentication.new(request).identifier,
            params: request.params
          }
        })
        result['data']['notifications'].each do |notification|
          env['auditing'].info(notification, request.params['flow_identifier']) if env['auditing']
        end
        result['data']['approved'] 
      rescue Exception => ex
        env['auditing'].error("Exception: #{ex.class}: #{ex.message}:\n\t#{ex.backtrace.join("\n\t")}", request.params['flow_identifier']) if env['auditing']
        false
      end
    end
  end
end
