require 'uri'
require 'jsender'

module SoarIdm
  class DirectoryProvider
    include Jsender

    def bootstrap(configuration)
      fail('Not implemented')
    end

    def bootstrapped?
      success_data({ 'bootstrap' => false })
    end

    def uri
      success_data({ 'uri' => URI("http://localhost").to_s })
    end

    def authenticate(credentials)
      fail('Not implemented')
    end

    def connect
      fail('Not implemented')
    end

    def connected?
      success_data({ 'connected' => false })
    end

    def ready?
      success_data({ 'ready' => false })
    end
  end
end