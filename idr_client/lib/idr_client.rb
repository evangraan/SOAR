require 'uri'
require 'json'
require 'net/http'
require 'soar_idm/soar_idm'

module SoarSc

  ##
  # SOAR Idr Client
  # Simplifies communication with Hetzner identity registries.
  # @example Get roles
  #   idr_client = SoarSc::IdrClient.new
  #   idr_client.roles_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-roles')
  #   subject_identifier = 'charles.mulder@example.org'
  #   roles = idr_client.get_roles(subject_identifier)
  # @example Get all attributes
  #   idr_client = SoarSc::IdrClient.new
  #   idr_client.attributes_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-attributes')
  #   subject_identifier = 'charles.mulder@example.org'
  #   attributes = idr_client.get_attributes(subject_identifier)
  # @example Get attributes filtered by role
  #   idr_client = SoarSc::IdrClient.new
  #   idr_client.roles_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-roles')
  #   idr_client.attributes_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-attributes')
  #   subject_identifier = 'charles.mulder@example.org'
  #   role = 'technical'
  #   attributes = idr_client.get_attributes(subject_identifier, role)
  class IdrClient < SoarIdm::IdmApi

    class MissingRequiredAttributeError < StandardError; end
    class CommunicationError < StandardError; end
    class UnsupportedResponseError < StandardError; end

    # @!attribute [w] roles_uri
    attr_writer :roles_uri

    # @!attribute [w] attributes_uri
    attr_writer :attributes_uri

    ##
    # Creates an instance of IdrClient
    # @param http optional [Object] 
    # @return [Object] instance of IdrClient
    def initialize(http=Net::HTTP)
      @http = http
    end

    ##
    # Get roles 
    # @param subject_identifier [String]
    # @raise MissingRequiredAttributeError when missing subject_identifier param
    # @raise UnsupportedResponseError when remote response is not json
    # @raise CommunicationError when network error
    # @return [Array] list of roles
    def get_roles(subject_identifier)
      begin
        super(subject_identifier)
      rescue MissingRequiredAttributeError => error
        raise error
      rescue JSON::ParserError => error
        raise UnsupportedResponseError, error.message
      rescue StandardError => error
        raise CommunicationError, error.message
      end
    end

    ##
    # Get attributes optionally filtered by role
    # @param subject_identifier [String]
    # @param role optional [String]
    # @raise MissingRequiredAttributeError
    # @raise UnsupportedResponseError
    # @raise CommunicationError
    # @return [Hash] dictionary of roles and attributes, optionally filtered by role
    def get_attributes(subject_identifier, role = nil)
      begin
        super(subject_identifier, role)
      rescue MissingRequiredAttributeError => error
        raise error
      rescue JSON::ParserError => error
        raise UnsupportedResponseError, error.message
      rescue StandardError => error
        raise CommunicationError, error.message
      end
    end

    ##
    # Set remote uri used by get_attributes method
    # @param attributes_uri [String]
    # @return [Nil]
    def attributes_uri=(attributes_uri)
      raise URI::InvalidURIError if not valid_url?(attributes_uri)
      @attributes_uri = URI.parse(attributes_uri)
    end

    ##
    # Set remote uri used by get_roles method
    # @param roles_uri [String]
    # @return [Nil]
    def roles_uri=(roles_uri)
      raise URI::InvalidURIError if not valid_url?(roles_uri)
      @roles_uri = URI.parse(roles_uri)
    end

    private 

    ##
    # @param entity_identifier [String]
    # @return [Array]
    def calculate_identities(entity_identifier)
      [entity_identifier]
    end

    ##
    # @param identity [String]
    # @return [Hash] attributes keyed by role
    def calculate_all_attributes(identity)
      response = ask_idr(identity, nil, @attributes_uri)
      response['data']['attributes']
    end

    ##
    # @param identity [String]
    # @return [Array] list of roles
    def calculate_roles(identity)
      raise MissingRequiredAttributeError, 'Missing required roles_uri' if @roles_uri.nil?
      response = ask_idr(identity, nil, @roles_uri)
      response['data']['roles']
    end

    ##
    # @param identity [String]
    # @param role optional [String] 
    # @return [Hash] dictionairy of attributes
    def calculate_attributes(identity, role = nil)
      raise MissingRequiredAttributeError, 'Missing required @attributes_uri attribute' if @attributes_uri.nil?
      response = ask_idr(identity, role, @attributes_uri)
      response['data']['attributes'][role]
    end 

    ##
    # @param identifier [String]
    # @param role optional [String]
    # @param url [URI::HTTP, URI::HTTPS] 
    # @return [Hash] parsed json response
    def ask_idr(identifier, role = nil, url)
      response = @http.start(url.host, url.port) do |http|
        params = build_params(identifier, role)
        http.get(url.path + params)
      end
      JSON.parse(response.body)
    end

    ##
    # @param identifier [String]
    # @param role optional [String]
    # @return [String] url query parameters
    def build_params(identifier, role = nil)
      params = "?identifier=#{identifier}"
      params += "&role=#{role}" if not role.nil?
      params
    end

    ##
    # @param uri [String] 
    # @return [Boolean]
    def valid_url?(uri)
      result = uri =~ /\A#{URI::regexp(['http', 'https'])}\z/
      not result.nil?
    end

  end
end
