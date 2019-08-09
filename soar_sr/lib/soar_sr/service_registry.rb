require 'jsender'
require 'soap4juddi'

module SoarSr
  class ServiceRegistry
    attr_reader :services
    attr_reader :service_definitions
    attr_reader :service_components
    attr_reader :domain_perspectives
    attr_reader :teams
    attr_reader :associations
    attr_reader :search
    attr_reader :broker
    attr_reader :contacts

    def initialize(uri, company, company_name, credentials, cache_freshness = 60)
      validate(uri, company, company_name, credentials)
      @urns = initialize_urns(company, company_name)
      @uddi = initialize_uddi_provider(uri, @urns, credentials, cache_freshness)
      initialize_handlers(@urns, @uddi, credentials)
    end

    def check_dss(name)
    end

    def self.build_urns(fqdn, company_name)
      base = "uddi:#{fqdn}"
      @urns = { 'base' => base,
                'company' => "#{base}:#{company_name}",
                'domains' => "#{base}:domains-",
                'teams' => "#{base}:teams-",
                'services' => "#{base}:services:",
                'service-components' => "#{base}:service-components:" }
      @urns
    end

    private

    def validate(uri, company, company_name, credentials)
      validator = SoarSr::Validator.new
      validator.provided?(uri, 'URI') and validator.uri?(uri)
      validator.provided?(company, 'company FQDN')
      validator.provided?(company_name, 'company name')
      validator.provided?(credentials, 'credentials') and validator.credentials?(credentials)
    end

    def initialize_urns(fqdn, company_name)
      SoarSr::ServiceRegistry::build_urns(fqdn, company_name)
    end

    def initialize_uddi_provider(uri, urns, credentials, cache_freshness)
      @broker = ::Soap4juddi::Broker.new(urns)
      @broker.base_uri = uri
      @uddi = ::SoarSr::JUDDIProvider.new(urns, @broker, cache_freshness)
    end

    def initialize_handlers(urns, uddi, credentials)
      initialize_service_handlers(urns, uddi, credentials)
      initialize_domain_handlers(urns, uddi, credentials)
      initialize_associations_and_search(urns, uddi, credentials)
      initialize_contacts(urns, uddi, credentials)
    end    

    def initialize_service_handlers(urns, uddi, credentials)
      @services = SoarSr::Services.new(urns, uddi, credentials, self)
      @service_definitions = SoarSr::ServiceDefinitions.new(urns, uddi, credentials, self)
      @service_components = SoarSr::ServiceComponents.new(urns, uddi, credentials, self)
    end

    def initialize_domain_handlers(urns, uddi, credentials)
      @domain_perspectives = SoarSr::DomainPerspectives.new(urns, uddi, credentials, self)
      @teams = SoarSr::Teams.new(urns, uddi, credentials, self)
    end

    def initialize_associations_and_search(urns, uddi, credentials)
      @associations = SoarSr::Associations.new(urns, uddi, credentials, self)
      @search = SoarSr::Search.new(urns, uddi, credentials, self)
    end      

    def initialize_contacts(urns, uddi, credentials)
      @contacts = SoarSr::Contacts.new(urns, uddi, credentials, self)
    end      
  end
end
