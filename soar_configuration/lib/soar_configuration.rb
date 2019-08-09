require 'uri'
require 'configuration_service'
require 'configuration_service/provider/vault'
require 'yaml'
require 'soar_configuration/configuration_validator'
require 'soar_configuration/version'

module SoarConfiguration
  class Configuration
    attr_accessor :errors

    def load_from_configuration_service(environment)
      @errors = []
      context = ConfigurationService::Factory::EnvironmentContext.new(environment)
      configuration_service = ConfigurationService::Factory.create_client(context)
      result = configuration_service.request_configuration
      config = result.data
      $stderr.puts "Loaded configuration #{result.identifier}: #{result.metadata.inspect}"
      return config, @errors

    rescue => e
      message = "Could not retrieve configuration from configuration service."
      @errors << 'invalid configuration service URI' if URI::InvalidURIError == e.class
      @errors << message
      @errors << e.message
      return nil, @errors
    end

    def load_from_yaml(filename)
      @errors = []
      config = YAML.load_file(filename)
      $stderr.puts "Loaded configuration #{filename}"
      
      if ((config == false) or (config.nil?))
        config = {}
        $stderr.puts "WARNING: Empty configuration! Set CFGSRV_IDENTIFIER to use the configuration service!"
      end
      return config, @errors

    rescue => e
      message = "Could not load or parse configuration file. Is it YAML?"
      @errors << message
      @errors << e.message
      return nil, @errors
    end

    def validate(config)
      @errors = []
      validator_class = config['validator']
      validator_class ||= 'SoarConfiguration::ConfigurationValidator'
      validator = Object::const_get(validator_class).new(config)
      @errors = validator.validate
    end
  end
end
