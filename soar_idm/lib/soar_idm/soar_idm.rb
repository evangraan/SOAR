require 'securerandom'
require "soar_idm/version"
require 'jsender'

module SoarIdm
  class IdentityError < StandardError
  end

  class IdmApi
    def get_roles(entity_identifier)
      return nil if invalid_entity_identifier?(entity_identifier) or no_entity_identifier?(entity_identifier)
      identity = get_identity(entity_identifier)
      calculate_roles(identity)
    end

    def get_attributes(entity_identifier, role = nil)
      return nil if invalid_entity_identifier?(entity_identifier) or no_entity_identifier?(entity_identifier)
      identity = get_identity(entity_identifier)
      return calculate_all_attributes(identity) if role_missing?(role) or no_role?(role)
      roles = get_roles(entity_identifier)
      return nil if roles.nil? or not(roles.include?(role))
      calculate_attributes(identity, role)
    end

    def get_identifiers(entity_identifier)
      return nil if invalid_entity_identifier?(entity_identifier) or no_entity_identifier?(entity_identifier)
      identity = get_identity(entity_identifier)
      calculate_identifiers(identity)
    end

    protected

    def calculate_roles(identity)
      []
    end

    def calculate_all_attributes(identity)
      {}
    end

    def calculate_attributes(identity, role)
      { role => {}}
    end 

    def calculate_identifiers(identity)
      [entity_identifier]
    end

    def calculate_identities(entity_identifier)
      [SecureRandom.uuid]
    end

    def get_identity(entity_identifier)
      identities = calculate_identities(entity_identifier)
      raise IdentityError.new("Error looking up identity for identifier #{entity_identifier}") if identities.nil?
      raise IdentityError.new("Multiple identities found for identifier #{entity_identifier}") if identities.size > 1
      raise IdentityError.new("Identities not found for identifier #{entity_identifier}") if identities.size == 0
      identities.first

    rescue => ex
      raise IdentityError.new("Failure looking up identity for #{entity_identifier}: #{ex}")
    end    

    private

    def invalid_entity_identifier?(entity_identifier)
      entity_identifier.nil? or not(entity_identifier.is_a?(String))
    end

    def no_entity_identifier?(entity_identifier)
      entity_identifier.strip == ""
    end

    def invalid_role?(role)
      role_missing?(role) or not(role.is_a?(String))
    end
    
    def role_missing?(role)
      role.nil?
    end

    def no_role?(role)
      role.strip == ""
    end
  end
end
