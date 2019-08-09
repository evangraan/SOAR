require 'jsender'
require 'soap4juddi'

module SoarSr
  class ServiceDefinitions < SoarSr::Handler
    include Jsender
    
    def register_service_definition(service, definition)_{
      service = standardize(service)            
      authorize 
      provided?(service, 'service') and registered?(service, 'services') and provided?(definition, 'service definition') and wadl?(definition)
      result = @uddi.get_service(service)
      service = result['data']
      service['definition'] = definition
      result = @uddi.save_service(service['name'], service['description'], service['definition'])
      authorized?(result) and identifier?(result, 'service')
      success('service definition registered')
    }end

    def service_definition_for_service(service)_{
      service = standardize(service)            
      # byebug
      provided?(service, 'service') and registered?(service, 'services')
      result = @uddi.get_service(service)['data']
      identifier?(result, 'service')
      return fail('service has no definition') if (result['definition'].nil?) or (result['definition'] == "")
      success_data({'definition' => result['definition']})
    }end

    def deregister_service_definition(service)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and registered?(service, 'services')
      result = @uddi.get_service(service)
      service = result['data']
      service['definition'] = ""
      result = @uddi.save_service(service['name'], service['description'], service['definition'])
      authorized?(result) and identifier?(result, 'service')
      success('service definition deregistered')
    }end
  end
end