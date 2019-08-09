require 'jsender'
require 'soap4juddi'
require 'persistent-cache'

module SoarSr
  class JUDDIProvider
    MAX_THREADS = 10 unless defined? MAX_THREADS; MAX_THREADS.freeze
    attr_reader :broker
    attr_reader :urns
    attr_reader :cache
    attr_reader :cache_freshness

    def initialize(urns, broker, cache_freshness)
      @urns = urns
      @broker = broker
      @cache_freshness = cache_freshness
      @cache = Persistent::Cache.new("uddi-broker", cache_freshness, Persistent::Cache::STORAGE_RAM)
    end

    def assign_service_to_business(name, business_key = @urns['company'])
      @broker.authorize
      result = get_service(name)
      service = result['data']
      @broker.save_service_element(service['name'], service['description'], service['definition'], @urns['services'], business_key)
    end

    def assign_service_component_to_business(name, business_key = @urns['company'])
      @broker.authorize
      result = get_service_component(name)
      service = result['data']
      @broker.save_service_element(service['name'], service['description'], service['definition'], @urns['service-components'], business_key)
    end

    def get_service(name)
      key = "get_service:#{name}"
      lookup_and_cache(key) do
        @broker.get_service_element(name, @urns['services'])
      end
    end

    def save_service(name, description = nil, definition = nil)
      @broker.authorize
      @broker.save_service_element(name, description.is_a?(Array) ? description : [description], definition, @urns['services'], @urns['company'])
    end

    def delete_service(name)
      @broker.authorize
      @broker.delete_service_element(name, @urns['services'])
    end

    def find_services(pattern = nil)
      pattern = pattern.nil? ? '%' : "%#{pattern}%"
      key = "find_services:#{pattern}"
      lookup_and_cache(key) do
        @broker.find_services(pattern)
      end
    end

    def add_service_uri(service, uri)
      result = remove_service_uri(service, uri)
      result = save_service_uri(service, uri) if result['status'] == 'success'
      result
    end

    def remove_service_uri(service, uri)
      @broker.authorize
      result = service_uris(service)
      existing_id = has_existing_binding?(result['data']['bindings'], uri) if has_bindings?(result)
      result = @broker.delete_binding(existing_id) if existing_id
      result
    end

    def service_uris(service)
      key = "service_uris:#{service}"
      lookup_and_cache(key) do
        @broker.find_element_bindings(service, @urns['services'])
      end
    end

    def get_service_component(name)
      key = "get_service_component:#{name}"
      lookup_and_cache(key) do
        @broker.get_service_element(name, @urns['service-components'])
      end
    end

    def save_service_component(name, description = nil, definition = nil)
      @broker.authorize
      @broker.save_service_element(name, description.is_a?(Array) ? description : [description], definition, @urns['service-components'], @urns['company'])
    end

    def delete_service_component(name)
      @broker.authorize
      @broker.delete_service_element(name, @urns['service-components'])
    end

    def find_service_components(pattern = nil)
      pattern = pattern.nil? ? '%' : "%#{pattern}%"
      key = "find_service_components:#{pattern}"
      lookup_and_cache(key) do
        @broker.find_service_components(pattern)
      end
    end

    def save_service_component_uri(service_component, uri)
      @broker.authorize
      result = @broker.find_element_bindings(service_component, @urns['service-components'])
      # only one binding for service components
      delete_existing_bindings(result['data']['bindings']) if has_bindings?(result)
      @broker.save_element_bindings(service_component, [uri], @urns['service-components'], "service component")
    end

    def find_service_component_uri(service_component)
      key = "find_service_component_uri:#{service_component}"
      lookup_and_cache(key) do
        @broker.find_element_bindings(service_component, @urns['service-components'])
      end
    end

    def save_business(key, name, description = nil, contacts = nil)
      @broker.authorize
      @broker.save_business(key, name, description, contacts)
    end

    def get_business(business_key)
      key = "get_business:#{business_key}"
      lookup_and_cache(key) do
        @broker.get_business(business_key)
      end
    end

    def find_businesses(pattern = nil)
      pattern = pattern.nil? ? '%' : "%#{pattern}%"
      key = "find_businesses:#{pattern}"
      lookup_and_cache(key) do
        @broker.find_business(pattern)
      end
    end

    def delete_business(key)
      @broker.authorize
      @broker.delete_business(key)
    end

    private

    def lookup_and_cache(key, &block)
      cached, refresh = lookup_and_refresh(key)
      refresh_entry(key) do
        block.call
      end if refresh
      return cached if cached
      value = block.call
      @cache[key] = value
      value
    end

    def refresh_entry(key, &block)
      return if Thread.list.size > MAX_THREADS
      Thread.new do
        begin
          # thread-safety not important. no mutexes required
          # we do not mind service stale cache values on
          # race conditions, since we refresh on half-life
          # of freshness on a best-effort basis
          value = block.call
          @cache[key] = value
        rescue => ex
          # do not update
        end
      end
    end

    def lookup_and_refresh(key)
      timestamp = @cache.timestamp?(key)
      halflife = @cache_freshness / 2
      refresh = false
      if (halflife > 0) and (timestamp)
        refresh = (Time.now - timestamp) > halflife
      end

      return @cache[key], refresh
    end

    def delete_existing_bindings(bindings)
      bindings.each do |binding, detail|
        @broker.delete_binding(binding)
      end
    end    

    def has_bindings?(result)
      result and result['data'] and result['data']['bindings'] and (result['data']['bindings'].size > 0)
    end

    def has_existing_binding?(bindings, uri)
      bindings.each do |binding, detail|
        return binding if detail['access_point'] == uri
      end
      nil
    end

    def save_service_uri(service, uri)
      @broker.authorize
      @broker.save_element_bindings(service, [uri], @urns['services'], "service uri") 
    end
  end
end
