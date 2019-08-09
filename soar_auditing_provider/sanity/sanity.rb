require 'soar_auditing_provider'
require 'log4r_auditor'
require 'soar_flow'

class Main

  AUDITING_CONFIGURATION = {
    'auditing' => {
      'level' => 'debug',
      'install_exit_handler' => 'true',
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
      }
    }
  }

  def test_sanity
    #create and configure auditing instance
    myauditing = SoarAuditingProvider::AuditingProvider.new( AUDITING_CONFIGURATION['auditing'] )
    myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
    myauditing.service_identifier = 'my-test-service.com'

    #associate a set of auditing entries with a flow by generating a flow identifiers
    flow_id = SoarFlow::ID::generate_flow_id

    #generate audit events
    some_debug_object = 123
    myauditing.info("This is info",flow_id)
    myauditing.debug(some_debug_object,flow_id)
    dropped = 95
    myauditing.warn("Statistics show that dropped packets have increased to #{dropped}%",flow_id)
    myauditing.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate",flow_id)
    myauditing.fatal("Unable to perform action, too many dropped packets. Functional degradation.",flow_id)
    myauditing << 'Rack::CommonLogger requires this'
  end
end

main = Main.new
main.test_sanity
