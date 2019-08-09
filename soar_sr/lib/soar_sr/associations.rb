require 'jsender'
require 'soap4juddi'
#require 'byebug'

module SoarSr
  class Associations < SoarSr::ThreadedHandler
    include Jsender

    def service_component_has_domain_perspective_associations?(service_component)_{
      service_component = standardize(service_component)
      provided?(service_component, 'service component')
      service_component_id = compile_domain_id('service-components', service_component)
      domain_perspectives = @registry.domain_perspectives.list_domain_perspectives['data']['domain_perspectives']
      domain_perspectives.each do |name, detail|
        service_components = domain_perspective_associations(name)['data']['associations']['service_components']
        service_components.each do |id, value|
          return true if (id == service_component_id) and (value)
        end
      end
      false      
    }end

    def associate_service_component_with_service(service, access_point, description = '')_{
      service = standardize(service)
      authorize
      provided?(service, 'service') and provided?(access_point, 'access point') and uri?(access_point)
      result = @uddi.add_service_uri(service, access_point)
      authorized?(result) and identifier?(result, 'service')
      success('service or access point')         
    }end

    def domain_perspective_associations(domain_perspective)_{
      # byebug
      domain_perspective = standardize(domain_perspective)      
      provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
      meta = @registry.domain_perspectives.meta_for_domain_perspective('domains', domain_perspective) if type_registered?(domain_perspective, 'domains')
      meta = @registry.domain_perspectives.meta_for_domain_perspective('teams', domain_perspective) if type_registered?(domain_perspective, 'teams')
      success_data(meta)
    }end

    def domain_perspective_has_associations?(domain_perspective)
      domain_perspective = standardize(domain_perspective)            
      associations = domain_perspective_associations(domain_perspective)['data']['associations']
      (associations['service_components'].size > 0) or (associations['services'].size > 0)
    end

    def service_associations(service)_{
      service = standardize(service)            
      provided?(service, 'service') and registered?(service, 'services')
      result = @registry.services.service_uris(service)

      bindings = result['data']['bindings']
      bindings ||= {}
      uris = {}
      bindings.each do |id, detail|
        uris[id] = detail['access_point']
      end

      service = {'id' => compile_domain_id('services', service), 'uris' => uris, 'associations' => { 'domain_perspectives' => {}}}
      domain_perspectives = @registry.domain_perspectives.list_domain_perspectives['data']['domain_perspectives']

      threads = []
      services = []
      domain_perspectives.each do |name, details|
        threads, services = domain_perspective_associations_threaded(threads, name, service, services)
      end
      join_threads(threads)
      services.each do |sv|
        service['associations']['domain_perspectives'] = 
          Hash::deep_merge(service['associations']['domain_perspectives'],
                           sv['associations']['domain_perspectives'])
      end
      success_data(service)
    }end

    def associate_service_component_with_domain_perspective(service_component, domain_perspective)_{
      service_component = standardize(service_component)      
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
      provided?(service_component, 'service component') and registered?(service_component, 'service-components')
      service_component_id = compile_domain_id('service-components', service_component)
      type_registered =  which_type_registered?(domain_perspective)

      meta = @registry.domain_perspectives.meta_for_domain_perspective('domains', domain_perspective) if type_registered == 'domains'
      meta = @registry.domain_perspectives.meta_for_domain_perspective('teams', domain_perspective) if type_registered == 'teams'

      raise ValidationError, 'already associated' if meta['associations']['service_components'][service_component_id]

      meta['associations']['service_components'][service_component_id] = true

      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('domains', domain_perspective, meta) if type_registered == 'domains'
      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('teams', domain_perspective, meta) if type_registered == 'teams'

      authorized?(result) and identifier?(result, 'domain perspective')
      success
    }end

    def associate_service_with_domain_perspective(service, domain_perspective)_{
      service = standardize(service)      
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
      provided?(service, 'service') and registered?(service, 'services')

      service_id = compile_domain_id('services', service)

      type_registered =  which_type_registered?(domain_perspective)      
      meta = @registry.domain_perspectives.meta_for_domain_perspective('domains', domain_perspective) if type_registered == 'domains'
      meta = @registry.domain_perspectives.meta_for_domain_perspective('teams', domain_perspective) if type_registered == 'teams'

      raise ValidationError, 'already associated' if meta['associations']['services'][service_id]

      meta['associations']['services'][service_id] = true

      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('domains', domain_perspective, meta) if type_registered == 'domains'
      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('teams', domain_perspective, meta) if type_registered == 'teams'
      authorized?(result) and identifier?(result, 'domain perspective')
      success
    }end

    def disassociate_service_component_from_domain_perspective(domain_perspective, service_component)_{
      service_component = standardize(service_component)      
      domain_perspective = standardize(domain_perspective)            
      # byebug
      provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
      provided?(service_component, 'service component') and registered?(service_component, 'service-components')

      service_component_id = compile_domain_id('service-components', service_component)

      type_registered =  which_type_registered?(domain_perspective)      
      meta = @registry.domain_perspectives.meta_for_domain_perspective('domains', domain_perspective) if type_registered == 'domains'
      meta = @registry.domain_perspectives.meta_for_domain_perspective('teams', domain_perspective) if type_registered == 'teams'
    
      raise ValidationError, 'not associated' if not meta['associations']['service_components'][service_component_id]

      meta['associations']['service_components'].delete(service_component_id)

      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('domains', domain_perspective, meta) if type_registered == 'domains'
      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('teams', domain_perspective, meta) if type_registered == 'teams'

      authorized?(result) and identifier?(result, 'domain perspective')
      success
    }end

    def disassociate_service_from_domain_perspective(domain_perspective, service)_{
      service = standardize(service)      
      domain_perspective = standardize(domain_perspective)            
      # byebug
      provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
      provided?(service, 'service') and registered?(service, 'services')

      service_id = compile_domain_id('services', service)

      type_registered =  which_type_registered?(domain_perspective)      
      meta = @registry.domain_perspectives.meta_for_domain_perspective('domains', domain_perspective) if type_registered == 'domains'
      meta = @registry.domain_perspectives.meta_for_domain_perspective('teams', domain_perspective) if type_registered == 'teams'

      raise ValidationError, 'not associated' if not meta['associations']['services'][service_id]

      meta['associations']['services'].delete(service_id)

      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('domains', domain_perspective, meta) if type_registered == 'domains'
      result = @registry.domain_perspectives.configure_meta_for_domain_perspective('teams', domain_perspective, meta) if type_registered == 'teams'

      authorized?(result) and identifier?(result, 'domain perspective')
      success
    }end

    def delete_all_domain_perspective_associations(domain_perspective)_{
      domain_perspective = standardize(domain_perspective)            
      # byebug
      provided?(domain_perspective, 'domain perspective')
      associations = domain_perspective_associations(domain_perspective)['data']['associations']
      associations['service_components'] ||= {}
      associations['services'] ||= {}
      associations['service_components'].each do |id, value|
        disassociate_service_component_from_domain_perspective(domain_perspective, extract_domain_name('service-components', id))
      end
      associations['services'].each do |id, value|
        disassociate_service_from_domain_perspective(domain_perspective, extract_domain_name('services', id))
      end
      success
    }end

    private

    def domain_perspective_associations_threaded(threads, domain_perspective, service, services)
      thread = nil
      threads = join_on_max_threads(threads)
      threads << Thread.new do
        result = map_domain_perspective_associations(domain_perspective, service)
        @@mutex.synchronize do
          services << result
        end
      end
      return threads, services
    end

    def map_domain_perspective_associations(domain_perspective, service)
      result = domain_perspective_associations(domain_perspective)
      result['data']['associations']['services'].each do |id, associated|
        if ((service['id'] == id) and (associated == true))
          service['associations'] ||= {}
          service['associations']['domain_perspectives'] ||= {}
          service['associations']['domain_perspectives'][domain_perspective] = domain_perspective
        end
      end
      service
    end

    def no_meta?(meta)
      (meta['associations']['service_components'] == {}) and (meta['associations']['services'] == {})
    end

    def which_type_registered?(domain_perspective)
      return 'domains' if type_registered?(domain_perspective, 'domains')
      return 'teams' if type_registered?(domain_perspective, 'teams')
      nil
    end

  end
end
