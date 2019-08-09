require 'jsender'
require 'soar_idm/soar_idm'
require 'idr_staff/configuration_validator'
require 'idr_staff/hetzner_staff_ldap'

module IdrStaff
  class StaffIdr < ::SoarIdm::IdmApi
    attr_reader :configuration
    attr_reader :status
    attr_reader :translator
    attr_reader :directory

    def bootstrap(configuration)
      validator = IdrStaff::ConfigurationValidator.new
      @status = validator.validate(configuration)
      @status
    end

    def initialize(configuration)
      @configuration = configuration
      bootstrap(configuration)
      initialize_providers(configuration) if bootstrapped?
    end

    def initialize_providers(configuration)
      @translator = Object::const_get(@configuration['rule_set']['adaptor']).new
      provider = @configuration['provider']
      @directory = Object::const_get(provider['adaptor']).new(provider)
      credentials = { 'username' => provider['username'], 'password' => provider['password'] }
      @directory.authenticate(credentials)
    end

    def bootstrapped?
      @status['status'] == 'success'
    end        

    def calculate_roles(identity)
      entry = @directory.get_entity(identity)
      return nil if not entry
      entity = translator.translate(entry)
      roles = []
      entity['roles'].each do |role, attributes|
        roles << role
      end
      roles
    end

    def calculate_all_attributes(identity)
      attributes = {}
      roles = calculate_roles(identity)
      roles.each do |role|
        attributes.merge!(calculate_attributes(identity, role))
      end
      attributes
    end

    def calculate_attributes(identity, role)
      entry = @directory.get_entity(identity)
      return nil if not entry
      entity = translator.translate(entry)
      { role => entity['roles'][role] }
    end 

    def calculate_identities(entity_identifier)
      entry = @directory.get_entity(entity_identifier)
      return nil if not entry
      entity = translator.translate(entry)
      [entity['uuid']]
    end
  end
end