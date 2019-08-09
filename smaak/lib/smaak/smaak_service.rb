require 'smaak.rb'
require 'smaak/server.rb'

module Smaak
  class SmaakService
    @@mutex = Mutex.new
    @@instance = nil
    attr_reader :smaak_server

    def self.get_instance(configuration = nil)
      @@mutex.synchronize do
        if (@@instance.nil?)
          @@instance = self.new(configuration)
        end
        @@instance
      end
    end

    def initialize(configuration = nil)
      @smaak_server = Smaak::Server.new
      configure_services(configuration)
    end

    def configure_services(_configuration = nil)
      # @smaak_server.set_public_key(File.read('/service-provider-pub.pem'))
      # @smaak_server.add_association('service-client-01', File.read('service-client-01-public.pem'), 'pre-shared-key')
    end
  end
end
