require "soar_environment/version"
require "soar_environment/environment_validator"
require "psych"
require "yaml"

module SoarEnvironment
  class LoadError < RuntimeError; end

  class Environment
    SOAR_CONFIGURATION_KEYS = ['IDENTIFIER', 'CAS_SERVER', 'SESSION_KEY', 'SESSION_SECRET'] if not defined? SOAR_CONFIGURATION_KEYS; SOAR_CONFIGURATION_KEYS.freeze

    attr_reader :environment_file
    attr_reader :environment

    def initialize(environment_file = nil)
      @environment_file = environment_file
    end

    def load_environment
      @environment = merge(load_file(@environment_file), load_env)
      raise ArgumentError.new("RACK_ENV not set in environment nor in properties or configuration") if (@environment['RACK_ENV'].nil?) or (@environment['RACK_ENV'].strip == "")
      @environment
    end

    def supplement_with_configuration(configuration, keys = SOAR_CONFIGURATION_KEYS)
      raise ArgumentError.new("configuration not provided") if (configuration.nil?)
      raise ArgumentError.new("configuration not valid") if not (configuration.is_a?(Hash))
      keys.each do |key|
        @environment[key] ||= configuration[key]
      end
      @environment
    end

    private

    # Produce a union of hashes, with duplicate keys overriden by the last specified hash to include them.
    def merge(*hashes)
      hashes.inject { |m, s| m.merge(s) }
    end

    def load_env
      env = (RUBY_PLATFORM == "java" ? java.lang.System.properties.merge(ENV) : ENV)
      env.to_h
    end

    def load_file(filename)
      if filename
        raise SoarEnvironment::LoadError.new("Failed to load file #{filename} : File does not exist") if not File.exist?(@environment_file)
        stringify_values(::YAML.load_file(filename))
      else
        {}
      end
    rescue IOError, SystemCallError, ::Psych::Exception => ex
      raise SoarEnvironment::LoadError.new("Failed to load file #{@environment_file} : #{ex}")
    end

    def stringify_values(hash)
      Hash[hash.map{ |k, v| [k, v.to_s] }]
    end      
  end
end
