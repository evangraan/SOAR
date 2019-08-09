require 'soar_xt'
require 'soar_flow'
require 'soar_auditing_provider'
require 'log4r_auditor'
require 'logstash_auditor'
require 'soar_analytics'
require 'soar_status'

module SoarSc
  module Providers
    class Auditing
      DEFAULT_AUDITING_CONFIGURATION = {
        'auditing' => {
          'provider' => 'SoarAuditingProvider::AuditingProvider',
          'level' => 'info',
          'install_exit_handler' => 'true',
          'add_caller_source_location' => 'false',
          'queue_worker' => {
            'queue_size' => 1000,
            'initial_back_off_in_seconds' => 1,
            'back_off_multiplier' => 2,
            'back_off_attempts' => 5
          },
          'default_nfrs' => {
            'accessibility' => 'local',
            'privacy' => 'not encrypted',
            'reliability' => 'instance',
            'performance' => 'high'
          },
          'auditors' => {
            'log4r' => {
              'adaptor' => 'Log4rAuditor::Log4rAuditor',
              'file_name' => 'soar_sc.log',
              'standard_stream' => 'stdout',
              'nfrs' => {
                'accessibility' => 'local',
                'privacy' => 'not encrypted',
                'reliability' => 'instance',
                'performance' => 'high'
              }
            }
            # 'logstash' => {
            #   'adaptor' => 'LogstashAuditor::LogstashAuditor',
            #   "host_url"    => "",
            #   "certificate"  => "",
            #   "private_key" => "",
            #   "timeout"     => 3,
            #   'nfrs' => {
            #     'accessibility' => 'centralized',
            #     'privacy' => 'not encrypted',
            #     'reliability' => 'high',
            #     'performance' => 'networked'
            #   }
            # }
          }
        }
      } unless defined? DEFAULT_AUDITING_CONFIGURATION; DEFAULT_AUDITING_CONFIGURATION.freeze

      def self.bootstrap(configuration, external_auditor = nil)
        begin
          if external_auditor
            SoarSc::auditing = external_auditor
          else
            configuration = self.merge_configuration_with_auditing_defaults(configuration)
            self.validate_auditing_provider_configuration(merged_configuration['auditing'])
            SoarSc::auditing = SoarSc::Providers.const_get(merged_configuration['auditing']['provider']).new(merged_configuration['auditing'])
            SoarSc::auditing.service_identifier = SoarSc::environment['IDENTIFIER']
            SoarStatus::Status.register_detailed_status_provider('auditing',SoarSc::auditing)
          end
          self.generate_instance_flow_id
          self.bootstrap_analytics
          configuration
        rescue
          $stderr.puts 'Failure initializing auditing provider'
          raise
        end
      end

      private

      def self.bootstrap_analytics
        SoarAnalytics::auditing = SoarSc::auditing
      end

      def self.generate_instance_flow_id
        SoarSc::startup_flow_id = SoarFlow::ID::generate_flow_id
      end

      def self.merge_configuration_with_auditing_defaults(configuration)
        Hash.deep_merge(DEFAULT_AUDITING_CONFIGURATION,SoarSc::configuration)
      end

      def self.validate_auditing_provider_configuration(configuration)
        begin
          SoarSc::Providers.const_get(configuration['provider'])
        rescue
          $stderr.puts 'Invalid auditing provider configuration'
          raise
        end
      end
    end
  end
end
