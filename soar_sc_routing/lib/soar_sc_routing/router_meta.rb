require 'json'
require 'soar/authorization/access_manager'
require 'soar_authorization'
require 'jsender'
require 'soar_aspects'

module SoarScRouting
  class RouterMeta
    include Jsender
    SIGNED = true unless defined? SIGNED; SIGNED.freeze
    UNSIGNED = false unless defined? UNSIGNED; UNSIGNED.freeze
    AUTHORIZED = true unless defined? AUTHORIZED; AUTHORIZED.freeze
    UNAUTHORIZED = false unless defined? UNAUTHORIZED; UNAUTHORIZED.freeze

    attr_accessor :configuration
    attr_accessor :lexicon
    attr_accessor :routing
    attr_accessor :signed_routes
    attr_accessor :service_names
    attr_accessor :policy_am
    attr_accessor :autenticate
    attr_reader   :name

    def initialize(configuration,name = 'router')
      @configuration = configuration
      @lexicon = {}
      @routing = {}
      @signed_routes = {}
      @service_names = {}
      @name = name
      setup_routing_table
    end

    def access_manager
      # TODO: Remove coupling to SoarSc::service_registry
      provider = Soar::Authorization::AccessManager::Provider::ServiceRegistry.new(SoarSc::service_registry)
      @policy_am ||= Soar::Authorization::AccessManager.new(provider)
      @policy_am
    end

    def register_route(detail, startup_flow_id = nil)
      validate_detail(detail)
      info("Registering service: #{detail} on router #{@name}", startup_flow_id)
      resource = SoarScRouting::Resource.new(detail['description'], "#{detail['service_name']}", upcase(detail['method']), detail['params'])
      add_resource_route(detail['path'], resource, interpret_secured(detail), interpret_authorized(detail)) do |request|
        if detail['controller']
          delegate_to_controller_and_renderer(detail, startup_flow_id, request)
        elsif detail['action']
          http_code, headers, body = detail['action'].call(request)
          [http_code, headers, [body]]
        end
      end
    end

    def add_route(path, description, &block)
      resource = SoarScRouting::Resource.new(description, generate_id(path))
      add_resource_route(path, resource, UNSIGNED, AUTHORIZED, &block)
    end

    def add_unsigned_unauthorized_route(path, description, &block)
      resource = SoarScRouting::Resource.new(description, generate_id(path))
      add_resource_route(path, resource, UNSIGNED, UNAUTHORIZED, &block)
    end

    def add_signed_route(path, description, &block)
      resource = SoarScRouting::Resource.new(description, generate_id(path))
      add_resource_route(path, resource, SIGNED, AUTHORIZED, &block)
    end

    def add_signed_unauthorized_route(path, description, &block)
      resource = SoarScRouting::Resource.new(description, generate_id(path))
      add_resource_route(path, resource, SIGNED, UNAUTHORIZED, &block)
    end

    protected

    # Inversion of control
    def setup_routing_table
    end

    # IoC renderer for views
    def render_view(detail, http_code, body)
      raise NotImplementedError.new "No renderer"
    end

    private

    def validate_detail(detail)
      raise ArgumentError.new("detail must not be nil") if detail.nil?
      raise ArgumentError.new("path must be provided") if detail['path'].nil?
      raise ArgumentError.new("path must start with /") if detail['path'][0] != '/'
      raise ArgumentError.new("description must be provided") if detail['description'].nil?
      raise ArgumentError.new("method must be provided") if detail['method'].nil?
      raise ArgumentError.new("service_name must be provided") if detail['service_name'].nil?
      raise ArgumentError.new("nfrs must be provided") if detail['nfrs'].nil?
      raise ArgumentError.new("nfrs['secured'] must be provided") if detail['nfrs']['secured'].nil?
      raise ArgumentError.new("nfrs['authorization'] must be provided") if detail['nfrs']['authorization'].nil?
    end

    def delegate_to_controller_and_renderer(detail, startup_flow_id, request)
      controller = nil
      begin
        controller = Object::const_get("SoarSc::Web::Controllers::#{detail['controller']}").new(@configuration)
      rescue NameError => ex
        warn("Could not instantiate SoarSc::Web::Controllers::#{detail['controller']}. Trying class name as-is", startup_flow_id)
        controller = Object::const_get(detail['controller']).new(@configuration)
      end
      http_code, body = controller.serve(request)
      render_view(detail, http_code, body)
    end

    def info(message, startup_flow_id)
      auditing = SoarAspects::Aspects::auditing
      if auditing
        auditing.info(message, startup_flow_id)
      else
        $stderr.puts(message)
      end
    end

    def warn(message, startup_flow_id)
      auditing = SoarAspects::Aspects::auditing
      if auditing
        auditing.warn(message, startup_flow_id)
      else
        $stderr.puts(message)
      end
    end

    def generate_id(path)
      path.gsub("/","_")
    end

    def add_resource_route(path, resource, signed, authorization_required, &block)
      @routing[path] = block
      @service_names[path] = resource.id
      @lexicon[path] = resource.content
      @signed_routes[path] = signed
      SoarAuthorization::Authorize::register_access_manager(path, resource.id, access_manager) if authorization_required
    end

    def interpret_secured(detail)
      secured = 'SIGNED' # default to strong
      if (not detail['nfrs']['secured'].nil?) and detail['nfrs']['secured'].is_a?(String)
        secured = 'SIGNED' if detail['nfrs']['secured'].upcase.strip == 'SIGNED'
        secured = nil if detail['nfrs']['secured'].upcase.strip == 'UNSIGNED'
      end
      secured == 'SIGNED'
    end

    def interpret_authorized(detail)
      authorized = 'AUTHORIZED' # default to strong
      if (not detail['nfrs'].nil?) and (not detail['nfrs']['authorization'].nil?) and (detail['nfrs']['authorization'].is_a?(String))
        authorized = detail['nfrs']['authorization']
        authorized = 'AUTHORIZED' if not ['AUTHORIZED', 'UNAUTHORIZED'].include?(detail['nfrs']['authorization'])
      end
      authorized == 'AUTHORIZED'
    end

    def upcase(methods)
      return methods.map(&:upcase) if methods.is_a?(Array)
      methods.upcase if methods.is_a?(String)
    end
  end
end
