require "soar_policy_access_manager/version"
require 'jsender'
require "soar_am"
require "soar_sr"

module SoarPolicyAccessManager
  class PolicyAccessManagerException < StandardError
  end

  class PolicyAccessManager < SoarAm::AmApi
    include Jsender
    attr_reader :service_registry

    def initialize(service_registry)
      @service_registry = service_registry
    end

    def authorize(service_identifier, resource_identifier, authentication_identifier, request)
      notifications = []
      decision = false

      begin
        if ENV['RACK_ENV'] == 'development'
          notifications << 'Authorized in development environment'
          decision = true
        end

        subject_identifier = authentication_identifier

        meta = @service_registry.services.meta_for_service(service_identifier)
        policy = meta['policy'] if meta and meta.is_a?(Hash) and meta['policy']

        if policy.nil?
          decision = true
          notifications << 'No policy associated with service'
        else
          decision, detail = ask_policy(policy, subject_identifier, service_identifier, resource_identifier, request)
          notifications.concat(detail) if not detail.empty?
          notifications << 'Policy rejected authorization request' if not decision
          notifications << 'Policy approved authorization request' if decision
        end
      rescue SoarSr::ValidationError => ex
        notifications << "AccessManager error authorizing #{service_identifier} for #{resource_identifier}: #{ex.message}"
        decision = false
      rescue Exception => ex
        notifications << "AccessManager error authorizing #{service_identifier} for #{resource_identifier}: #{ex.message}"
        decision = false
      end

      success(notifications, { 'approved' => decision } )
    end

    private

    def ask_policy(policy, subject_identifier, service_identifier, resource_identifier, request)
      notifications = []
      uri = find_first_uri(policy)
      if uri.nil?
        notifications << "Could not retrieve policy for service"
        return false, notifications
      end
      url = URI.parse(uri)
      params = { 'resource_identifier' => resource_identifier,
                 'subject_identifier' => subject_identifier,
                 'service_identifier' => service_identifier,
                 'request' => request,
                 'flow_identifier' => request['flow_identifier'] }
      res = Net::HTTP.post_form(url, params)
      result = JSON.parse(res.body)
      if result['status'] == 'error'
        notifications << 'Policy query result was not success'
        return false, notifications
      end
      return result['data']['allowed'], notifications
    rescue => ex
      notifications << "Exception while asking policy #{ex.message}"
      return false, notifications
    end

    def find_first_uri(policy)
      result = @service_registry.services.service_by_name(policy)
      return nil if not result['status'] == 'success'
      return nil if result['data']['services'].nil? or result['data']['services'].first.nil?
      service = result['data']['services'].first
      return nil if service[1].nil? or service[1]['uris'].nil?
      access = service[1]['uris'].first
      return nil if access.nil? or access[1].nil? or access[1]['access_point'].nil?
      access[1]['access_point']
    end
  end
end
