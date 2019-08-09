module SoarAuditorApi
  class AuditorAPI
    AUDIT_LEVELS = [:debug, :info, :warn, :error, :fatal] unless defined? AUDIT_LEVELS; AUDIT_LEVELS.freeze
    DEFAULT_AUDIT_LEVEL = :info unless defined? DEFAULT_AUDIT_LEVEL; DEFAULT_AUDIT_LEVEL.freeze

    def initialize(configuration = nil)
      @minimum_audit_level = DEFAULT_AUDIT_LEVEL
      configure(configuration) if configuration
    end

    def configure(configuration = nil)
      raise ArgumentError, "Invalid configuration provided" unless configuration_is_valid?(configuration)
      prefer_direct_call?
      @configuration = configuration
    end

    def set_audit_level(minimum_audit_level)
      raise ArgumentError, "Invalid audit level specified" unless AUDIT_LEVELS.include?(minimum_audit_level)
      @minimum_audit_level = minimum_audit_level
    end

    def debug(data)
      audit(data.to_s) if audit_filtered_out?(:debug)
    end

    def <<(data)
      audit(data.to_s) if audit_filtered_out?(:info)
    end

    def info(data)
      audit(data.to_s) if audit_filtered_out?(:info)
    end

    def warn(data)
      audit(data.to_s) if audit_filtered_out?(:warn)
    end

    def error(data)
      audit(data.to_s) if audit_filtered_out?(:error)
    end

    def fatal(data)
      audit(data.to_s) if audit_filtered_out?(:fatal)
    end

    #Safety to ensure that the Auditor that extends this API implements this IOC method
    def configuration_is_valid?(configuration)
      raise NotImplementedError, "Class must implement configuration_is_valid? method in Auditor extending the API"
    end

    #Safety to ensure that the Auditor that extends this API implements this IOC method
    def audit(data)
      raise NotImplementedError, "Class must implement audit method in Auditor extending the API"
    end

    def prefer_direct_call?
      raise NotImplementedError, "Class must implement prefer_direct_call? method in Auditor extending the API"
    end

    private

    def audit_filtered_out?(audit_level)
      return AUDIT_LEVELS.index(@minimum_audit_level) <= AUDIT_LEVELS.index(audit_level)
    end
  end
end
