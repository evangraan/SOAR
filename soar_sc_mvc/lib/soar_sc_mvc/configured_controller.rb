require 'smaak'
require 'smaak/client'
require 'net/http'
require 'uri'

module SoarSc
  module Web
    module Controllers
      class ConfiguredController
        attr_accessor :configuration
        attr_accessor :policies
        attr_accessor :dependencies
        attr_accessor :smaak_client

        def initialize(configuration, policies = nil)
          @configuration = configuration
          @policies = policies
          @dependencies = SoarSc::dependencies
          configure_smaak_client if smaak_enabled?
        end

        def body(request)
          return nil if request.body.nil?
          return request.body.gets if request.body.is_a? Rack::Lint::InputWrapper
          return request.body.string if request.body.is_a? StringIO
          request.body
        end

        def serve(request)
          [ 501, "Not implemented" ]
        end

        def smaak_client
          SoarSc::auditing.warn("SMAAK not enabled, and so I don't have a SMAAK client",SoarSc::startup_flow_id) if not smaak_enabled?
          @smaak_client
        end

        def auditing
          SoarAspects::Aspects::auditing
        end

        protected

        def smaak_enabled?
          (@configuration['private_key'] and @configuration['associations']) or
          (@configuration['smaak'] == 'dynamic')
        end

        def configure_smaak_client
          @smaak_client = ::Smaak::Client.new
          secure_service = SoarSmaak::SecureService.get_instance(@configuration)
          if secure_service.dynamic
            secure_service.trust_store.associations.each do |identifier, association|
              @smaak_client.add_association(identifier, association['public_key'], association['psk'], association['encrypt'])
            end
            @smaak_client.set_identifier(secure_service.dynamic)
            @smaak_client.set_private_key(secure_service.trust_store.associations[secure_service.dynamic]['private_key'])
          else
            @smaak_client.set_identifier(SoarSc::environment['IDENTIFIER'])
            @smaak_client.set_private_key(@configuration['private_key'])
            @configuration['associations'].each do |identifier, association|
              @smaak_client.add_association(identifier, association['public_key'], association['psk'], association['encrypt'])
            end
          end
        end
      end
    end
  end
end
