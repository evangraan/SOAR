require "soar_sr/version"
require "soar_sr/validation_error"
require "soar_sr/validator"
require "soar_sr/handler"
require "soar_sr/threaded_handler"
require "soar_sr/services"
require "soar_sr/service_components"
require "soar_sr/service_definitions"
require "soar_sr/domain_perspectives"
require "soar_sr/teams"
require "soar_sr/search"
require "soar_sr/contacts"
require "soar_sr/associations"
require "soar_sr/juddi_provider"
require "soar_sr/service_registry"
require "soar_xt"
require 'jsender'

module SoarSr
	DOMAIN_TYPES = ['domains', 'services', 'service-components', 'teams'] unless defined? DOMAIN_TYPES; DOMAIN_TYPES.freeze
end