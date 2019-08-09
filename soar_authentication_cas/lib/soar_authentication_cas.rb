require "soar_authentication_cas/version"

module SoarAuthenticationCas
  def self.cas_servers(environment)
    { 'production' => environment['CAS_SERVER'],
      'development' => environment['CAS_SERVER'], }
  end

  def self.configure(environment)
    return nil if environment.nil? or environment['RACK_ENV'].nil?
    self.validate(environment)
    signon_prefix = cas_servers(environment)[environment['RACK_ENV']]
    are_we_in_development = ( environment['RACK_ENV'] == 'development' )
    { :prefix => signon_prefix,
      :browsers_only => are_we_in_development,
      :ignore_certificate => are_we_in_development }
  end

  private

  def self.validate(environment)
    errors = []
    errors << 'invalid authentication provider uri' if not environment['CAS_SERVER'] =~ URI::regexp
    self.abort_on_validation_failures(errors) if not errors.empty?
  end

  def self.abort_on_validation_failures(errors)
    errors << 'Failure initializing authentication provider' if not errors.empty?
    raise URI::InvalidURIError.new(errors) if not errors.empty?
  end
end
