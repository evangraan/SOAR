require 'jsender'
require 'soap4juddi'
require 'json'
# require 'byebug'

module SoarSr
  class DomainPerspectives < SoarSr::Handler
    include Jsender

    def delete_all_domain_perspectives()_{
      authorize
      result = list_domain_perspectives
      if has_data?(result, 'domain_perspectives') 
        result['data']['domain_perspectives'].each do |name, detail|
          @uddi.delete_business(detail['id'])
        end
      end
    }end

    def domain_perspective_by_name(type, domain_perspective)
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, one_of(type))
      @uddi.get_business(compile_domain_id(type, domain_perspective))
    end

    def list_domain_perspectives(domain_types = SoarSr::DOMAIN_TYPES)_{
      result = @uddi.find_businesses
      result['data']['domain_perspectives'] ||= {}

      if has_data?(result, 'businesses')
        result['data']['businesses'].each do |business, detail|
          hetz = false
          domain_types.each do |type|
            hetz = true if detail['id'].include?(type)
          end
          result['data']['domain_perspectives'][business] = detail if hetz
        end
      end
      result['data'].delete('businesses')
      result
    }end

    def domain_perspective_registered?(domain_perspective)_{
      domain_registered?('domains', domain_perspective)
    }end

    def register_domain_perspective(domain_perspective)_{
      register_domain('domains', domain_perspective)
    }end

    def deregister_domain_perspective(domain_perspective)_{
      deregister_domain('domains', domain_perspective)
    }end

    def configure_meta_for_domain_perspective(type, domain_perspective, meta)_{
      domain_perspective = standardize(domain_perspective)            
      authorize
      provided?(domain_perspective, one_of(type)) and registered?(domain_perspective, type)
      provided?(type, 'element type') and type?(type)
      provided?(meta, 'meta') and meta?(meta)
      # byebug
      
      detail = extract_detail_for_domain_perspective(type, domain_perspective)
      descriptions = extract_non_meta_descriptions_for_domain_perspective(detail)
      # byebug
      detail['description'] = compile_meta_into_descriptions(descriptions, meta)

      result = @uddi.save_business(detail['id'], detail['name'], detail['description'], detail['contacts'])
      authorized?(result) and identifier?(result, type)
      success('meta updated', result['data'])
    }end

    def meta_for_domain_perspective(type, domain_perspective)_{
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, one_of(type)) and registered?(domain_perspective, type)
      provided?(type, 'element type') and type?(type)
      meta = extract_meta_for_domain_perspective(extract_detail_for_domain_perspective(type, domain_perspective))
      meta['associations'] ||= {}
      meta['associations']['service_components'] ||= {}
      meta['associations']['services'] ||= {}
      meta     
    }end

    protected

    def domain_registered?(type, domain_perspective)
      domain_perspective = standardize(domain_perspective)            
      provided?(domain_perspective, one_of(type))
      result = @uddi.find_businesses(domain_perspective)
      registered = false
      id = nil
      if has_data?(result, 'businesses')
        result['data']['businesses'].each do |business, detail|
          if (domain_perspective.downcase == business.downcase) and (detail['id'].include?(type))
            registered = true
            id = detail['id']
          end
        end
      end
      success_data({'registered' => registered, 'id' => id})
    end    

    def register_domain(type, domain_perspective)_{
      domain_perspective = standardize(domain_perspective)            
      authorize
      provided?(domain_perspective, one_of(type)) and not_registered?(domain_perspective, type)
      id = compile_domain_id(type, domain_perspective)
      result = @uddi.save_business(id, domain_perspective)
      authorized?(result) and identifier?(result, type)
      success('domain perspective registered')
    }end

    def deregister_domain(type, domain_perspective)_{
      domain_perspective = standardize(domain_perspective)            
      authorize
      provided?(domain_perspective, one_of(type)) and registered?(domain_perspective, type)
      raise ValidationError, 'domain perspective has associations' if @registry.associations.domain_perspective_has_associations?(domain_perspective)
      result = @uddi.delete_business(compile_domain_id(type, domain_perspective))
      authorized?(result) and identifier?(result, type)
      success('domain perspective deregistered')
    }end    

    private

    def extract_non_meta_descriptions_for_domain_perspective(detail)
      descriptions = []
      detail['description'] ||= []        
      detail['description'].each do |desc|
        descriptions << desc if not description_is_meta?(desc)
      end
      descriptions
    end

    def extract_detail_for_domain_perspective(type, domain_perspective)
      provided?(domain_perspective, one_of(type)) and provided?(type, 'domain type')
      id = compile_domain_id(type, domain_perspective)
      detail = @uddi.get_business(id)['data'][domain_perspective]      
      detail ||= {}
      detail['id'] = id
      detail
    end

    def extract_meta_for_domain_perspective(detail)
      meta = {}
      if detail['description']
        detail['description'].each do |desc|
          meta = Hash::deep_merge(meta, JSON.parse(CGI.unescape(desc))) if (description_is_meta?(desc))
        end
      end
      meta
    end

    def compile_meta_into_descriptions(descriptions, meta)
      associations = {}
      associations.merge!(meta['associations']) if meta['associations']
      associations['service_components'] ||= {}
      associations['services'] ||= {}
      meta.delete('associations')
      associations['service_components'].each do |id, value|
        descriptions << CGI.escape({'associations' => {'service_components' => {id => value}}}.to_json)
      end
      associations['services'].each do |id, value|
        descriptions << CGI.escape({'associations' => {'services' => {id => value}}}.to_json)
      end

      descriptions << CGI.escape(meta.to_json) if meta.count > 0
      descriptions
    end
  end
end