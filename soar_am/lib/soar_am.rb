require "soar_am/version"
require "soar_authentication"

module SoarAm
  class AmApi
    def authorized?(service_identifier, resource_identifier, request)
      authentication = SoarAuthentication::Authentication.new(request)
      return false if not authentication.authenticated?

      authorize(service_identifier, resource_identifier, authentication.identifier, request.params)
    end

    def authorize(service_identifier, resource_identifier, authentication_identifier, params)
      raise NotImplementedError.new "Not implemented"
    end
  end
end
