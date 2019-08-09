module SoarConfiguration
  class ConfigurationValidator
    attr_reader :configuration
    def initialize(configuration)
      @configuration = configuration
    end

    def validate
      errors = []
      errors << 'invalid configuration' if not @configuration.is_a?(Hash)
      errors = validate_presence(errors)
      errors
    end

    # IOC to check whether parameters exist
    def validate_presence(errors)
      #errors = validate_exists(@configuration['providers'], "providers", errors)
      #errors = validate_exists(@configuration['providers']['products'], "products")
      errors
    end

    protected

    def validate_exists(entry, description, errors)
      if entry.nil? or entry == ""
        message = "#{description} must be defined"
        errors << message
      end
      errors
    end
  end
end