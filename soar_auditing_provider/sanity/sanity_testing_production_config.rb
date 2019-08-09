require 'soar_auditing_provider'
require 'log4r_auditor'
require 'logstash_auditor'
require 'soar_flow'
require 'configuration_service'

class Main

  def get_config_from_config_service
    #where to get the token
    #https://configuration-service.auto-h.net/#authorize

    #docs where this code comes from
    #http://www.rubydoc.info/gems/configuration_service-provider-vault
    require 'bundler'
    Bundler.require(:default)
    ENV['CFGSRV_IDENTIFIER']="auditing_for_production"
    ENV['CFGSRV_TOKEN']="43f8f6f5-6f9c-87fb-e71e-0cea7fe58c07" #TODO fill this in
    ENV['CFGSRV_PROVIDER']="vault"
    ENV['CFGSRV_PROVIDER_ADDRESS']="https://vault.auto-h.net"
    config_service = ConfigurationService::Factory.create_client
    config = config_service.request_configuration
    config.data
  end

  def test_sanity

    config = get_config_from_config_service

    #OVERRIDE TO JSON if required
    #config['output_format'] = 'json'

    #OVERRIDE TO LOCAL ELK STACK if required
    config['auditors']['logstash']["host_url"] = "https://logstash-staging1.jnb1.host-h.net:8080"
    #config['auditors']['logstash']["certificate"]  = File.read("../../logstash_auditor/spec/support/certificates/selfsigned/selfsigned_registered.cert.pem")
    #config['auditors']['logstash']["private_key"] = File.read( "../../logstash_auditor/spec/support/certificates/selfsigned/selfsigned_registered.private.nopass.pem")

    $stderr.puts config

    #config = load_yaml_file('production_config.yml')

    #create and configure auditing instance
    myauditing = SoarAuditingProvider::AuditingProvider.new( config )
    myauditing.startup_flow_id = SoarFlow::ID::generate_flow_id
    myauditing.service_identifier = 'my-test-service.com'

    #associate a set of auditing entries with a flow by generating a flow identifiers
    flow_id = SoarFlow::ID::generate_flow_id

    #generate audit events
    some_debug_object = 123

    debug_hash = { "info" => "bla" }

    myauditing.info(debug_hash,flow_id)


    # myauditing.debug(some_debug_object,flow_id)
    # dropped = 95
    # myauditing.warn("Statistics show that dropped packets have increased to #{dropped}%",flow_id)
    # myauditing.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate",flow_id)
    # myauditing.fatal("Unable to perform action, too many dropped packets. Functional degradation.",flow_id)
    # myauditing << 'Rack::CommonLogger requires this'

    sleep 3
  end

  def load_yaml_file(file_name)
    require 'yaml'
    if File.exist?(file_name)
      YAML.load_file(file_name)
    else
      {}
    end
  rescue IOError, SystemCallError, Psych::Exception => ex
    raise LoadError.new("Failed to load yaml file #{file_name} : #{ex}")
  end
end

main = Main.new
main.test_sanity
