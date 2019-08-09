require 'jsender'
require 'soap4juddi'

module SoarSr
  class Search < SoarSr::Handler
    include Jsender
    
    def query_service_by_pattern(pattern)_{
      provided?(pattern, 'pattern')
      result = @uddi.find_services
      list = {}        
      if has_data?(result, 'services')
        result['data']['services'].each do |service, name|
          detail = @uddi.get_service(service)
          if has_data?(detail, 'description')
            found = false
            dss = nil
            detail['data']['description'].each do |description|
              found = true if (description and description.include?(pattern))
              dss = description.gsub("dss:", "").strip if (description and description.include?('dss:'))
            end
            list[service] = detail if ((dss and (@dss and check_dss(service))) or (not dss)) and found
          end
        end
      end

      success_data({ 'services' => list })
    }end

    def search_services_for_uri(pattern)_{
      provided?(pattern, 'pattern') and length_at_least?(pattern, 4, 'pattern')
      result = @registry.services.list_services
      found = extract_services_with_uris_that_match_from_data(result, pattern)
      success_data({'services' => found})       
    }end

    def search_for_service_component(pattern, full_text = true)
      services = search_for_service(pattern, true, full_text)
      service_components = {}
      if services['status'] == 'success'
        services['data']['services'].each do |service, detail|
          service_components[service] = detail if detail['key'].include?('service-components')
        end
        result = success_data({'services' => service_components})
      end
      result
    end

    def search_for_service(pattern, include_service_components = true, full_text = true)_{
      provided?(pattern, 'pattern') and length_at_least?(pattern, 4, 'pattern')

      services = {}
      service_components = {}
      services_list = @uddi.find_services(pattern)['data']['services'] if not include_service_components
      services_list, service_components_list = @registry.services.find_services_and_service_components(nil) if include_service_components
      services_list.each do |service, detail|
        service_name = extract_domain_name('services', service)
        if full_text
          data = @uddi.get_service(service)['data'] if full_text
          if search_for_pattern_in_hash_values(data, pattern)
            services[service_name] = data
            services[service_name]['uris'] = @registry.services.service_uris(service_name)['data']['bindings']
          end
        else
          if service_name == service
            services[service_name] = detail
            services[service_name]['uris'] = @registry.services.service_uris(service_name)['data']['bindings']
          end
        end
      end
      if (include_service_components)
        service_components_list.each do |service_component, detail|
          service_name = extract_domain_name('services-components', service_component)
          if full_text
            data = @uddi.get_service_component(service_component)['data']
            service_components[service_name] = data if search_for_pattern_in_hash_values(data, pattern)
          else
            service_components[service_name] = detail if service_name == service_component
          end
        end
      end
      found = services.merge!(service_components)

      success_data({'services' => found})
    }end

    def search_access_points(pattern)
      found = []
      result = @registry.services.list_services['data']['services']
      result ||= {}
      result.each do |service, detail|
        uris = detail['uris']
        uris ||= {}
        uris.each do |id, access_details|
          access_details ||= {}
          access_point = access_details['access_point']
          access_point ||= ""
          included = (not((access_point =~ /#{pattern}/i).nil?))
          found << service if (included and (not found.include?(service)))
        end
      end
      success_data({'services' => found})
    end    

    def search_domain_perspective(domain_perspective, pattern)_{
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, 'domain perspective') and registered?(domain_perspective, 'domains')

      found = {}
      data = @registry.associations.domain_perspective_associations(domain_perspective)['data']['associations']
      services = {}
      service_components = {}
      services_list = data['services']
      service_components_list = data['service_components']
      services_list.each do |service, detail|
        data = @uddi.get_service(service)['data']
        services[extract_domain_name('services', service)] = data if search_for_pattern_in_hash_values(data, pattern)
      end
      service_components_list.each do |service_component, detail|
        data = @uddi.get_service_component(service_component)['data']
        service_components[extract_domain_name('services-components', service_component)] = data if search_for_pattern_in_hash_values(data, pattern)
      end
      found = services.merge!(service_components)
      success_data({'services' => found})
    }end

    private

    def search_for_pattern_in_hash_values(data, pattern)
      data.keys.each do |key|
        value = data[key]
        return true if (not value.is_a?(Hash)) and (value.to_s.include?(pattern))
        return true if (value.is_a?(Hash)) and (search_for_pattern_in_hash_values(value, pattern))
      end
      return false
    end

    def extract_services_with_uris_that_match_from_data(result, pattern)
      found = {}
      if has_data?(result, 'services')
        services = result['data']['services']
        found = extract_services_with_uris_that_match(found, services, pattern)
      end
    end

    def extract_services_with_uris_that_match(found, services, pattern)
      services.each do |service, detail|
        found = extract_matching_uris_for_services(found, service, detail, pattern)
      end 
      found     
    end

    def extract_matching_uris_for_services(found, service, detail, pattern)
      uris = detail['uris']
      uris ||= {}
      append_matching_uris(found, service, uris, pattern)
    end

    def append_matching_uris(found, service, uris, pattern)
      uris.each do |id, access_details|
        extract_uris_from_access_details(found, access_details, service, pattern)
      end
      found      
    end

    def extract_uris_from_access_details(found, access_details, service, pattern)
      uri = access_details['access_point']
      if (not((uri =~ /#{pattern}/i).nil?))
        found[service] ||= []
        found[service] << uri
      end
      found
    end    
  end
end