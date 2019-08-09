require 'jsender'
require 'soap4juddi'

module SoarSr
  class ServiceComponents < SoarSr::Handler
    include Jsender
    
    def delete_all_service_components()_{
      authorize
      result = list_service_components
      if has_data?(result, 'service_components') 
        result['data']['service_components'].each do |name, detail|
          @uddi.delete_service_component(name)
        end
      end
    }end

    def list_service_components(domain_perspective = nil)_{
      domain_perspective = standardize(domain_perspective)            
      return fail('unknown domain perspective provided') if domain_perspective and (not is_registered?(@registry.domain_perspectives.domain_perspective_registered?(domain_perspective)))

      result = @uddi.find_service_components
      service_components = has_data?(result, 'services') ? result['data']['services'] : {}
      found = []

      if not domain_perspective.nil?
        associations = @registry.associations.domain_perspective_associations(domain_perspective)['data']['associations']['service_components']
        return success_data({'service_components' => []}) if associations.count == 0
        
        associations.each do |id, associated|
          if associated
            service_components.each do |sid, service_component|
              found << sid if compile_domain_id('service-components', sid) == id
            end
          end
        end
      else
        service_components.each do |sid, service_component|
          found << sid
        end
      end

      success_data('service_components' => found)
    }end

    def service_component_registered?(service_component)_{
      service_component = standardize(service_component)            
      result = @uddi.find_service_components(service_component)
      if has_data?(result, 'services')
        result['data']['services'].each do |service_key, description|
          return success_data({'registered' => true}) if (service_component.downcase == service_key.downcase)
        end
      end
      success_data({'registered' => false})
    }end

    def register_service_component(service_component)_{
      service_component = standardize(service_component)            
      authorize
      provided?(service_component, 'service component') and not_registered?(service_component, 'service-components')

      result = @uddi.save_service_component(service_component)
      authorized?(result) and identifier?(result, 'service component')
      success('service component registered')        
    }end

    def deregister_service_component(service_component)_{
      service_component = standardize(service_component)            
      # byebug
      authorize
      provided?(service_component, 'service component') and registered?(service_component, 'service-components')
      raise ValidationError, 'service component has domain perspective associations' if @registry.associations.service_component_has_domain_perspective_associations?(service_component)
      result = @uddi.delete_service_component(service_component)
      authorized?(result) and identifier?(result, 'service component')
      success('service component deregistered') 
    }end

    def configure_service_component_uri(service_component, uri)_{
      service_component = standardize(service_component)            
      authorize
      provided?(service_component, 'service component') and provided?(uri, 'URI') and uri?(uri) and registered?(service_component, 'service-components')
      result = @uddi.save_service_component_uri(service_component, uri)
      authorized?(result) and identifier?(result, 'service component')
      success
    }end

    def service_component_uri(service_component)_{
      service_component = standardize(service_component)            
      provided?(service_component, 'service component') and registered?(service_component, 'service-components')
      result = @uddi.find_service_component_uri(service_component)
      identifier?(result, 'service component')
      uri = (has_data?(result, 'bindings') and (result['data']['bindings'].size > 0)) ? result['data']['bindings'].first[1]['access_point'] : nil
      result['data']['uri'] = uri
      success_data(result['data'])
    }end

    def configure_meta_for_service_component(service_component, meta)_{
      service_component = standardize(service_component)            
      authorize
      provided?(service_component, 'service component') and provided?(meta, 'meta') and meta?(meta) and registered?(service_component, 'service-components')
      descriptions = merge_meta_with_service_component_descriptions(service_component, meta)
      result = update_service_component_descriptions(service_component, descriptions)

      authorized?(result) and identifier?(result, 'meta')
      success('meta updated', result['data'])
    }end

    def meta_for_service_component(service_component)
      service_component = standardize(service_component)            
      provided?(service_component, 'service component') and registered?(service_component, 'service-components')
        detail = @uddi.get_service_component(service_component)['data']
        if detail['description']
          detail['description'].each do |desc|
            return JSON.parse(CGI.unescape(desc)) if (description_is_meta?(desc))
          end
        end
        {}      
    end

    private

    def merge_meta_with_service_component_descriptions(service_component, meta)
      detail = @uddi.get_service_component(service_component)['data']
      merge_meta_with_descriptions(detail, meta)
    end

    def update_service_component_descriptions(service_component, descriptions)
      detail = @uddi.get_service_component(service_component)['data']
      detail['description'] = descriptions
      @uddi.save_service_component(detail['name'], detail['description'], detail['definition'])
    end
  end
end