require 'yaml'

module SoarSmaak
  class SmaakTrustStore
    attr_reader :associations

    def initialize
      @errors = []
      @associations = YAML.load_file('config/smaak_trust_store')['associations']

    rescue => e
      message = "Could not load SMAAK trust store. Is it YAML?"
      @errors << message
      @errors << e.message
      raise ArgumentError.new(message)
    end
  end
end