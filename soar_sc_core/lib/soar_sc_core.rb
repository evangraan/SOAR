require 'pathname'
$: << Pathname('.') + 'lib'

DEFAULT_STATIC_OPTIONS = { "urls" => ["/wadl", "/fonts", "/css", "/img", "/modernizr", "/jquery", "/foundation", "/js", "/favicon.ico"], "root" => "public" } if not defined? DEFAULT_STATIC_OPTIONS; DEFAULT_STATIC_OPTIONS.freeze

def require_technology
  require 'byebug' if ENV['SOAR_TECH'] == 'debug'
  require 'rack'
  require 'net/http'
end

def require_configuration
  require 'soar_configuration'
end

def require_environment
  require 'soar_aspects'
  require 'soar_environment'
end

def require_routing
  require 'soar_sc_routing'
  require 'web/soar_sc_router'
end

def require_web
  require 'soar_sc_views'
  require 'haml'
  require 'soar_wadl_validation'
  require 'soar_lexicon'
  require 'soar_sc_mvc'
  Dir["#{Dir.pwd}/lib/web/controllers/*.rb"].each {|file| require file }
  Dir["#{Dir.pwd}/lib/web/views/*.rb"].each {|file| require file }
  Dir["#{Dir.pwd}/lib/web/validators/*.rb"].each {|file| require file }
end

def require_auth
  require 'soar_smaak'
  require 'soar_authentication'
  require 'soar_authentication_cas'
  require 'soar_authentication_token'
  Dir["#{Dir.pwd}/lib/authorization/*.rb"].each {|file| require file }
end

def require_models
  require 'soar/dependency_container'
  require 'soar_configured_factory'
  Dir["#{Dir.pwd}/lib/web/models/*.rb"].each {|file| require file }
end

def require_database_adaptors
  Dir["#{Dir.pwd}/lib/providers/storage/*.rb"].each {|file| require file }
end

def require_providers
  require 'soar_sr'
  Dir["#{Dir.pwd}/lib/providers/**/*.rb"].each {|file| require file }
  Dir["#{Dir.pwd}/lib/providers/*.rb"].each {|file| require file }
end

def require_core
  require 'soar_sc_core'
end

require_technology
require_routing
require_environment
require_configuration
require_web
require_models
require_database_adaptors
require_providers
require_auth
require_core

module SoarSc
  @service_registry = nil
  @configuration = nil
  @environment = {}
  @auditing = nil
  @dependencies = {}
  @startup_flow_id = nil

  def self.load_environment_and_configuration
    environment_file = ENV['ENVIRONMENT_FILE'] ? "config/#{ENV['ENVIRONMENT_FILE']}" : 'config/environment.yml'
    if File.exists?(environment_file)
      environment_loader = SoarEnvironment::Environment.new(environment_file)
    else
      environment_loader = SoarEnvironment::Environment.new
    end
    SoarSc::environment = environment_loader.load_environment
    config = SoarSc::load_configuration
    SoarSc::environment = environment_loader.supplement_with_configuration(config)
    validator = SoarEnvironment::EnvironmentValidator.new
    errors = validator.validate(SoarSc::environment)
    raise ArgumentError.new(errors) if (errors) and (not (errors.empty?))
    config
  rescue Exception
    $stderr.puts 'Failure retrieving environment from file'
    raise
  end

  def self.load_configuration
    configuration = SoarConfiguration::Configuration.new
    if SoarSc::environment['CFGSRV_IDENTIFIER']
      self.validate_configuration_service_token
      config, errors = configuration.load_from_configuration_service(SoarSc::environment)
      self.adapt_configuration_service_errors(errors)
    else
      config_file = SoarSc::environment['CONFIG_FILE'] ? SoarSc::environment['CONFIG_FILE'] : "config.yml"
      config, errors = configuration.load_from_yaml("config/#{config_file}")
      errors << 'Failure retrieving configuration from file' if not errors.empty?
      errors << 'Invalid configuration file' if not config.is_a?(::Hash)
    end
    errors << 'missing configuration' if config.nil?
    errors = configuration.validate(config) if (errors) and (errors.empty?)
    raise ArgumentError.new(errors) if (errors) and (not (errors.empty?))

    SoarSc::configuration = config
    config
  end

  def self.adapt_configuration_service_errors(errors)
    errors << 'missing configuration service URI' if errors.include?('missing key address')
    errors << 'incorrect configuration service token' if errors.include?('permission denied')
    errors << 'failure retrieving configuration from configuration service' if not errors.empty?
  end

  def self.validate_configuration_service_token
    raise ArgumentError.new('missing configuration service token') if SoarSc::environment['CFGSRV_TOKEN'].nil?
    raise ArgumentError.new('invalid configuration service token') if SoarSc::environment['CFGSRV_TOKEN'].length < 12
  end

  def self.inject_dependencies(configuration)
    if configuration and configuration['dependency_injector']
      injector = Object::const_get(configuration['dependency_injector']).new
      @dependencies = injector.inject_dependencies(configuration)
    else
      @dependencies = {}
    end

    @dependencies
  end

  def self.bootstrap_sessions(stack)
    if (SoarSc::environment['SESSION_KEY'] or SoarSc::environment['SESSION_SECRET'])
      session_provider = SoarSc::Providers::Sessions.new
      session_provider.bootstrap_sessions(stack)
    end
  end

  def self.bootstrap_authentication(stack)
    if 'development' == ENV['RACK_ENV']
      SoarSc::auditing.warn("Authentication ignored in development mode.")
    elsif SoarSc::configuration['auth_token']
      SoarSc::auditing.info("Using auth tokens for authentication with <#{SoarSc::configuration['auth_token']['provider']}> provider.",SoarSc::startup_flow_id)
      stack.use SoarAuthenticationToken::RackMiddleware, SoarSc::configuration['auth_token'], SoarSc::environment['IDENTIFIER'], SoarSc::auditing
    elsif SoarSc::environment['CAS_SERVER']
      SoarSc::auditing.info("Using CAS_SERVER=#{SoarSc::environment['CAS_SERVER']} for authentication",SoarSc::startup_flow_id)
      options = SoarAuthenticationCas::configure(SoarSc::environment)
      stack.use KhSignon::RackMiddleware, options if options
    elsif SoarSc::environment['BASIC_AUTH_USER']
      SoarSc::auditing.warn("BASIC_AUTH_USER specified, using basic auth for authentication. Basic auth is not recommended for production",SoarSc::startup_flow_id)
      stack.use Rack::Auth::Basic, "Restricted Area" do |username, password|
        [username, password] == [SoarSc::environment['BASIC_AUTH_USER'], SoarSc::environment['BASIC_AUTH_PASSWORD']]
      end
    else
      SoarSc::auditing.warn("Neither Authentication Tokens, CAS_SERVER or BASIC_AUTH_USER specified. Having no authentication is not recommended for production",SoarSc::startup_flow_id)
    end
  end

  def self.bootstrap_aspects(config, authenticated_meta, lexicon)
    SoarAspects::Aspects::configuration = config
    SoarAspects::Aspects::signed_routes = authenticated_meta.signed_routes
    SoarAspects::Aspects::auditing = SoarSc::auditing
    SoarAspects::Aspects::lexicon = lexicon
  end

  def self.static_options
    static_options = SoarSc::configuration['static_options'] || DEFAULT_STATIC_OPTIONS

    { :urls => static_options['urls'], :root => static_options['root'] }
  end

  def self.self_test
    Thread.new do |thread|
      sleep 1
      url = URI.parse('http://localhost:9393/status')
      res = Net::HTTP.get(url)
      puts "SELF-TEST: #{res}"

      if RUBY_PLATFORM =~ /java/
        java.lang.System.exit(1)
      else
        exit 0
      end
    end
  end

  def self.dependencies
    @dependencies
  end

  def self.service_registry
    @service_registry
  end

  def self.configuration
    @configuration
  end

  def self.environment
    @environment
  end

  def self.environment=(environment)
    @environment = environment
  end

  def self.auditing
    @auditing
  end

  def self.auditing=(auditing)
    @auditing = auditing
  end

  def self.startup_flow_id
    @startup_flow_id
  end

  def self.startup_flow_id=(startup_flow_id)
    @startup_flow_id = startup_flow_id
  end

  def self.service_registry=(service_registry)
    @service_registry = service_registry
  end

  def self.configuration=(configuration)
    @configuration = configuration
  end
end

require "providers/auditing"
require "web/renderer"
require "web/soar_sc_router"
require "providers/service_registry"
require "providers/sessions"
require "soar_sc_core/version"

module SoarScCore
end
