require 'jsender'
require 'soap4juddi'
require 'json'
#require 'byebug'

module SoarSr
  class Services < SoarSr::ThreadedHandler
    include Jsender
    ALL_SERVICES = nil unless defined? ALL_SERVICES; ALL_SERVICES.freeze

    def register_service(service, description = nil)_{
      service = standardize(service)            
      authorize
      key_provided?(service, 'name', 'service') and not_registered?(service['name'], 'services')
      result = @uddi.save_service(service['name'], extract_description_and_meta(service, description), service['definition'])
      authorized?(result) and identifier?(result, 'service')
      success('service registered')
    }end

    def deregister_service(service)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and registered?(service, 'services')
      result = @uddi.delete_service(service)
      authorized?(result) and identifier?(result, 'service')
      success('service deregistered')
    }end

    def service_registered?(service)_{
      service = standardize(service)            
      registered = false
      if present?(service)
        result = @uddi.find_services(service)      
        registered = find_matching_service(service, result) if has_data?(result, 'services')
      end
      success_data({'registered' => (registered ||= false)})
    }end

    def add_service_uri(service, uri)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and provided?(uri, 'URI') and uri?(uri) and registered?(service, 'services')
      result = @uddi.add_service_uri(service, uri)
      authorized?(result) and identifier?(result, 'service')
      success
    }end

    def service_uris(service)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and registered?(service, 'services')
      result = @uddi.service_uris(service)
      authorized?(result) and identifier?(result, 'service')
      success_data(result['data'])
    }end

    def remove_uri_from_service(service, uri)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and provided?(uri, 'URI') and uri?(uri) and registered?(service, 'services')
      result = @uddi.remove_service_uri(service, uri)
      authorized?(result) and identifier?(result, 'service')
      success
    }end

    def configure_meta_for_service(service, meta)_{
      service = standardize(service)            
      authorize
      provided?(service, 'service') and provided?(meta, 'meta') and meta?(meta) and registered?(service, 'services')

      descriptions = merge_meta_with_service_descriptions(service, meta)
      result = update_service_descriptions(service, descriptions)

      authorized?(result) and identifier?(result, 'meta')
      success('meta updated', result['data'])
    }end

    def meta_for_service(service)
      service = standardize(service)            
      provided?(service, "service") and registered?(service, 'services')
        detail = @uddi.get_service(service)['data']
        if detail['description']
          detail['description'].each do |desc|
            return JSON.parse(CGI.unescape(desc)) if (description_is_meta?(desc))
          end
        end
        {}      
    end

    def service_by_name(name)_{
      name = standardize(name)            
      provided?(name, "service")
      services = find_service(name)
      return extract_service_by_name_from_services_list(services, name) if has_data?(services, 'services')
      raise FailureErrorError, 'failure finding service by name'
    }end

    def find_services_and_service_components(pattern)
      services = @uddi.find_services(pattern)['data']['services']
      service_components = @uddi.find_service_components(pattern)['data']['services']
      services ||= {}
      service_components ||= {}
      return services, service_components
    end    

    def list_services
      found = find_service_by_pattern(ALL_SERVICES)

      success_data({'services' => found})      
    end

    private

    def find_matching_service(service, result)
      result['data']['services'].each do |service_key, description|
        return true if (service.downcase == service_key.downcase)
      end
      false
    end

    def extract_description_and_meta(service, description = nil)
      result = []
      result << service['description'] if service['description'] and description.nil?
      result << description if not description.nil?
      result << service['meta'] if service['meta']
      result
    end

    def find_service(pattern)
      provided?(pattern, "pattern") and length_at_least?(pattern, 4, "pattern")

      found = find_service_by_pattern(pattern)

      success_data({'services' => found})
    end

    def extract_service_by_name_from_services_list(result, name)
      result['data']['services'].each do |sname, service|
        compare_service = "#{@urns['services']}#{name}" == sname
        compare_service_component = "#{@urns['service-components']}#{name}" == sname
        return success_data({ 'services' => { sname => service }}) if compare_service or compare_service_component or (name == sname)
      end
      success_data({ 'services' => {}})      
    end 

    def merge_meta_with_service_descriptions(service, meta)
      detail = @uddi.get_service(service)['data']
      merge_meta_with_descriptions(detail, meta)
    end

    def update_service_descriptions(service, descriptions)
      detail = @uddi.get_service(service)['data']
      detail['description'] = descriptions
      @uddi.save_service(detail['name'], detail['description'], detail['definition'])
    end

    def find_service_by_pattern(pattern)
      services, service_components = find_services_and_service_components(pattern)
      services = map_service_uris(services)
      found = services.merge!(service_components)
      found
    end

    def map_service_uris(services)
      threads = []
      services.each do |id, service|
        threads = map_service_uri_threaded(threads, service)
      end
      join_threads(threads)
      services
    end

    def map_service_uri_threaded(threads, service)
      thread = nil
      threads = join_on_max_threads(threads)
      threads << Thread.new do
        map_service_uri_thread_safe(service)
      end
      threads
    end

    def map_service_uri_thread_safe(service)
      name = service_name_thread_safe(service)
      result = service_uris(name)
      uris = result['data'].nil? ? {} : result['data']['bindings']
      service_uris_thread_safe(service, uris)
    end

    def service_name_thread_safe(service)
      name = nil
      @@mutex.synchronize do
        name = service['name']
      end
      name
    end

    def service_uris_thread_safe(service, uris)
      @@mutex.synchronize do
        service['uris'] = uris
      end      
      service
    end
  end
end
