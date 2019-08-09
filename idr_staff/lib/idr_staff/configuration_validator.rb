require 'jsender'

module IdrStaff
  class ConfigurationValidator
    include Jsender

    def validate(configuration)
      return fail 'invalid configuration provided' if not valid_configuration?(configuration)
      return fail 'no rule set provided' if not configuration_present_for?(configuration, 'rule_set')
      return fail 'no provider provided' if not configuration_present_for?(configuration, 'provider')

      begin
        return fail 'invalid rule set provided' if not valid_rule_set?(configuration)
      rescue => ex
        return fail 'failure bootstrapping rule set'
      end

      begin
        return fail 'invalid provider provided' if not valid_provider?(configuration)
      rescue => ex
        return fail 'failure bootstrapping provider'
      end

      success
    end

    private

    def valid_configuration?(configuration)
      return false if configuration.nil?
      return false if not configuration.is_a?(Hash)
      return false if configuration['valid'] != 'valid'
      true
    end

    def valid_rule_set?(configuration)
      adaptor = extract_adaptor('rule_set', configuration)
      return false if adaptor == ''
      return false if not class_exists?(adaptor)
      klass = Module.const_get(adaptor)
      return false if not (klass.public_instance_methods.include?(:translate))
      true
    end

    def valid_provider?(configuration)
      adaptor = extract_adaptor('provider', configuration)
      return false if adaptor == ''
      return false if not class_exists?(adaptor)
      raise RuntimeError if adaptor == 'RuntimeError'
      klass = Module.const_get(adaptor)
      # Someone please tell me why klass.is_a?(SoarIdm::DirectoryProvider) is not working here?
      return false if 
        not (klass.superclass.name == "SoarIdm::DirectoryProvider") and
        not (klass.superclass.superclass.name == "SoarIdm::DirectoryProvider")
      connector = extract_category('provider', configuration)
      return false if connector['path'].nil?
      return false if connector['server'].nil?
      return false if connector['port'].nil?
      return false if connector['username'].nil?
      return false if connector['password'].nil?
      true
    end

    def configuration_present_for?(configuration, category)
      not configuration[category].nil?
    end

    def extract_adaptor(category, configuration)
      configuration[category]['adaptor'].to_s.strip
    end

    def extract_category(category, configuration)
      configuration[category]
    end


    def class_exists?(class_name)
      klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end
  end
end