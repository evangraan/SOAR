module SoarSc
  module Providers
    class ServiceRegistry
      def self.bootstrap(config)
        begin
          if SoarSc::dependencies.include?("service_registry")
            SoarSc::auditing.info("Using registry from configured dependencies", SoarSc::startup_flow_id)
            SoarSc::service_registry = SoarSc::dependencies["service_registry"]
          else
            credentials = { 'username' => 'uddi', 'password' => 'read-only' }
            registry = config['service_registry']['uri'] if config['service_registry']
            registry = SoarSc::environment['SERVICE_REGISTRY'] if SoarSc::environment['SERVICE_REGISTRY']
            SoarSc::auditing.info("Using registry at [#{registry}]",SoarSc::startup_flow_id)
            SoarSc::auditing.error("No service registry! Missing service registry URI",SoarSc::startup_flow_id) if ((registry.nil?) or ('' == registry))
            freshness = 3600
            freshness = config['service_registry']['freshness'] if config['service_registry'] and config['service_registry']['freshness']
            SoarSc::service_registry = SoarSr::ServiceRegistry.new(registry, 'hetzner.co.za', 'hetzner', credentials, freshness)
          end

          config['service_registry']['warm_up'].each do |service_identifier|
            SoarSc::auditing.info("SoarSc::Provider::ServiceRegistry Warming up #{service_identifier}",SoarSc::startup_flow_id)
            SoarSc::service_registry.services.service_by_name(service_identifier)
            SoarSc::service_registry.services.meta_for_service(service_identifier)
          end if config['service_registry'] and config['service_registry']['warm_up']
        rescue
          SoarSc::auditing.fatal("Service registry client failure",SoarSc::startup_flow_id)
          raise
        end
      end

      def self.find_first_service_uri(identifier)
        result = SoarSc::service_registry.services.service_by_name(identifier)
        SoarSc::auditing.error("Failure to look up service in service registry",SoarSc::startup_flow_id) if not result['status'] == 'success'
        return nil if not result['status'] == 'success'
        return nil if result['data']['services'].nil? or result['data']['services'].first.nil?
        service = result['data']['services'].first
        return nil if service[1].nil? or service[1]['uris'].nil?
        access = service[1]['uris'].first
        return nil if access.nil? or access[1].nil? or access[1]['access_point'].nil?
        access[1]['access_point']
      end

      def self.find_best_service_uri(identifier)
        status_map = {}
        result = SoarSc::service_registry.services.service_by_name(identifier)
        SoarSc::auditing.error("Failure to look up service in service registry",SoarSc::startup_flow_id) if not result['status'] == 'success'
        return nil if not result['status'] == 'success'
        return nil if result['data']['services'].nil? or result['data']['services'].first.nil?
        result['data']['services'].each do |service|
          next if service[1].nil? or service[1]['uris'].nil?
          access = service[1]['uris']
          next if access.nil?
          access.each do |access_point|
            next if access_point[1].nil? or access_point[1]['access_point'].nil?
            uri = access_point[1]['access_point']
            url = URI.parse(uri)
            components = url.path.split('/')
            status = "#{url.path.split('/')[0..(components.size - 2)].join('/')}/status"
            url.path = status
            health = -2
            begin
              res = Net::HTTP.get(url)
            rescue => ex
              health = -1
            end
            begin
              health = res.to_i
            rescue => ex
              health = 0
            end
            status_map[uri] = health
          end
        end

        best_uri = (status_map.sort_by { |uri, health| health })[-1]
        best_uri.nil? ? nil : best_uri[0]
      end
    end
  end
end
