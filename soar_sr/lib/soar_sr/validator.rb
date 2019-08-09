require 'jsender'
require 'soap4juddi'

module SoarSr
  class Validator
    include Jsender

    def present?(field)
      not (field.nil? or (field.is_a?(String) and field.strip == ""))
    end

    def provided?(field, label)
      raise ValidationError, "no #{label} provided" if field.nil?
      raise ValidationError, "invalid #{label} provided" if (field.is_a?(String) and field.strip == "")
      true
    end

    def key_provided?(field, key, label)
      msg_no = "no #{label} provided"
      msg_invalid = "invalid #{label} provided"
      raise ValidationError, msg_no if field.nil?
      raise ValidationError, msg_invalid if (not field.is_a? Hash)
      raise ValidationError, msg_no if field[key].nil?
      raise ValidationError, msg_invalid if (not field[key].is_a? String) or (field[key].strip == "")
      true
    end


    def length_at_least?(field, min, label)
      raise ValidationError, "invalid #{label} provided" if (field.size < min)
      true
    end

    def credentials?(credentials)
    	provided?(credentials, 'credentials') and provided?(credentials['username'], 'username') and provided?(credentials['password'], 'password')
    end

    def authorized?(result)
      raise ValidationError, 'not authorized' if (notifications_include?(result, 'E_authTokenRequired')) or 
                                                 (notifications_include?(result, 'E_keyUnavailable')) or
                                                 (notifications_include?(result, 'E_userMismatch')) or
                                                 (notifications_include?(result, 'not authorized'))
      true
    end

    def identifier?(result, label)
      raise ValidationError, "invalid #{label} identifier provided" if notifications_include?(result, 'E_invalidKeyPassed')
      true
    end

    def uri?(uri)
      raise ValidationError, 'invalid URI' if not (uri =~ URI::DEFAULT_PARSER.regexp[:UNSAFE]).nil?
      true
    end

    def meta?(meta)
      raise ValidationError, 'invalid meta' if not meta.is_a?(Hash)
      true
    end

    def type?(type)
      ['domains', 'services', 'teams', 'service-components'].include?(type)
    end

    def wadl?(definition)
      raise ValidationError, 'invalid service definition provided' if not definition.include?("wadl")
      true
    end

    def contact?(contact)
      error = 'invalid contact details provided'
      raise ValidationError, error if not contact.is_a?(Hash)
      raise ValidationError, error if contact['name'].nil? or contact['name'].strip == ""
      true
    end

    def one_of(type)
      result = type[0..-2]
      result = 'domain perspective' if result == 'domain'
      result = 'service component' if result == 'service-component'
      result
    end     
  end
end
