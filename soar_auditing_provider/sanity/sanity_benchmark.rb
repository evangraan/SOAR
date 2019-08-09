require 'soar_auditing_provider'
require 'log4r_auditor'
require 'soar_flow'
require 'benchmark'
require 'byebug'

class Main

  AUDITING_CONFIGURATION = {
    'auditing' => {
      'level' => 'debug',
      'install_exit_handler' => 'false',
      'add_caller_source_location' => 'false',
      'queue_worker' => {
        'queue_size' => 1000000,
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
          'standard_stream' => 'none',
          'nfrs' => {
            'accessibility' => 'local',
            'privacy' => 'not encrypted',
            'reliability' => 'instance',
            'performance' => 'high'
          }
        }
      }
    }
  }

  def test_sanity
    iterations = 1000000

    #create and configure auditing instance
    myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'] )
    myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
    myauditing.service_identifier = 'my-test-service.com'

    #associate a set of auditing entries with a flow by generating a flow identifiers
    flow_id = SoarFlow::ID::generate_flow_id

    Benchmark.bm do |x|
      myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'].dup.merge("level" => "warn") )
      myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
      myauditing.service_identifier = 'my-test-service.com'
      x.report ("audit_call_below_audit_threshold:") {
        iterations.times {
          myauditing.info("Benchmarking test",flow_id)
        }
      }
      myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'].dup.merge("add_caller_source_location" => "false") )
      myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
      myauditing.service_identifier = 'my-test-service.com'
      x.report ("audit_call_without_caller_info  :") {
        iterations.times {
          myauditing.info("Benchmarking test",flow_id)
        }
      }
      myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'].dup.merge("add_caller_source_location" => "true") )
      myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
      myauditing.service_identifier = 'my-test-service.com'
      x.report ("audit_call_with_caller_info     :") {
        iterations.times {
          myauditing.info("Benchmarking test",flow_id)
        }
      }
    end
  end
end

main = Main.new
main.test_sanity
