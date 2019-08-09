require 'jsender'
require 'soap4juddi'

module SoarSr
	class Handler < Validator
		include Jsender

    attr_accessor :registry

    def initialize(urns, uddi, credentials, registry)
    	@urns = urns
    	@uddi = uddi
    	@credentials = credentials
      @registry = registry
    	validate
    end

    def authorize
      @uddi.broker.authenticate(@credentials['username'], @credentials['password'])
    end

    protected

    def _(&block)
    	yield
    rescue => ex
    	# byebug
      return fail(ex.message) if ex.is_a? ValidationError
      return error('request could not be completed')      	
    end

    def description_is_meta?(meta)
      JSON.parse(CGI.unescape(meta))
      true
    rescue => ex
      false
    end

    def is_registered?(result)
      has_data?(result, 'registered') and result['data']['registered']
    end

    def type_registered?(element, type)
      return is_registered?(@registry.domain_perspectives.domain_perspective_registered?(element)) if (type == 'domains')
      return is_registered?(@registry.service_components.service_component_registered?(element)) if (type == 'service-components')
      return is_registered?(@registry.services.service_registered?(element)) if (type == 'services')
      return is_registered?(@registry.teams.team_registered?(element)) if (type == 'teams')
      false
    end

    def not_registered?(element, type)
      raise ValidationError, "#{one_of(type)} already exists" if type_registered?(element, type)
      true
    end

    def any_registered?(domain_perspective)
      raise ValidationError, "unknown domain perspective provided" if (not type_registered?(domain_perspective, 'domains')) and (not type_registered?(domain_perspective, 'teams'))
      true
    end

    def registered?(element, type)
      raise ValidationError, "unknown #{one_of(type)} provided" if not type_registered?(element, type)
      true
    end   

    def validate
    	provided?(@urns, "urns") and provided?(@uddi, "UDDI provider") and credentials?(@credentials)
    end

    def compile_domain_id(type, element)
      element = standardize(element)
      return element if element.include?(@urns[type])
      "#{@urns[type]}#{element}"
    end        

    def extract_domain_name(type, element)
      element = standardize(element)
      element.gsub("#{@urns[type]}", "")
    end

    def standardize(name)
      return standardize_dictionary(name) if name.is_a?(Hash)
      return standardized = name.to_s.downcase if not name.nil?
      nil
    end

    def merge_meta_with_descriptions(detail, meta)
      descriptions = []
      detail['description'] ||= {}
      detail['description'].each do |desc|
        descriptions << desc if not description_is_meta?(desc)
      end
      descriptions << CGI.escape(meta.to_json)
      descriptions
    end

    private

    def standardize_dictionary(dictionary)
      value = standardize(dictionary['name'])
      standardized = dictionary
      standardized['name'] = value
      standardized
    end
  end
end
