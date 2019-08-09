module SoarEnvironment
  class EnvironmentValidator
    VALID_EXECUTION_ENVIRONMENTS = ['production','development'] unless defined? VALID_EXECUTION_ENVIRONMENTS; VALID_EXECUTION_ENVIRONMENTS.freeze

    def validate(environment)
      errors = []
      errors << 'invalid service identifier' if (environment['IDENTIFIER'].nil?) or (environment['IDENTIFIER'].strip == "")
      errors << 'Missing execution environment indicator' if (environment['RACK_ENV'] == 'none') or (environment['RACK_ENV'].nil?) or (environment['RACK_ENV'].strip == "")
      errors << 'Invalid execution environment indicator' if not VALID_EXECUTION_ENVIRONMENTS.include?(environment['RACK_ENV'])
      errors
    end
  end
end