module SoarSmaak
  class SecureService < ::Smaak::SmaakService
    attr_reader :dynamic
    attr_reader :trust_store
    @@auditing = nil

    def self.auditing=(auditing)
      @@auditing = auditing
    end

    def self.auditing
      @@auditing
    end

    def self.smaak_configured?(configuration)
      (not configuration['public_key'].nil?) and
      (not configuration['private_key'].nil?) and
      (not configuration['associations'].nil?)
    end

    def self.smaak_dynamic?(configuration)
      configuration['smaak'] and (configuration['smaak'].downcase.strip == 'dynamic')
    end

    def debug(message)
      if SoarSmaak::SecureService::auditing.nil?
        puts message
      else
        SoarSmaak::SecureService::auditing.debug(message)
      end
    end

    def configure_services(configuration)
      if (not SoarSmaak::SecureService::smaak_configured?(configuration) and
          SoarSmaak::SecureService::smaak_dynamic?(configuration))
        seed_dynamic_smaak
      elsif (SoarSmaak::SecureService::smaak_configured?(configuration))
        configure_smaak(configuration)
      else
        debug "SMAAK is neither dynamic nor configured. SMAAK support disabled"
      end
    end

    def seed_dynamic_smaak
      debug "SMAAK credentials not provided."
      load_smaak_trust_store
      randomize_smaak
    end

    def randomize_smaak
      @dynamic = @trust_store.associations.keys[rand(@trust_store.associations.keys.size)]
      debug "Seeding random key-pair and identifier"
      @smaak_server.set_public_key(@trust_store.associations[@dynamic]['public_key'])
      @smaak_server.set_private_key(@trust_store.associations[@dynamic]['private_key'])
      @smaak_server.verify_recipient = false
    end

    def load_smaak_trust_store
      @trust_store = SoarSmaak::SmaakTrustStore.new
      @trust_store.associations.each do |identifier, config|
        @smaak_server.add_association(identifier, config['public_key'], config['psk'], config['encrypt'])
      end
    end

    def configure_smaak(configuration)
      @smaak_server.set_public_key(configuration['public_key'])
      @smaak_server.set_private_key(configuration['private_key'])
      configuration['associations'].each do |identifier, config|
        @smaak_server.add_association(identifier, config['public_key'], config['psk'], config['encrypt'])
      end
      debug "SMAAK credentials provided. SMAAK configured"
    end
  end
end