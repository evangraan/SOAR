require 'jsender'

module SoarPl
  class AuthorizationPolicy
    include Jsender

    attr_reader :policy_identifier
    attr_reader :subject_identifier
    attr_reader :requestor_identifier
    attr_reader :request
    attr_reader :configuration
    attr_reader :rule_set
    attr_reader :idm
    attr_reader :roles
    attr_accessor :status
    attr_accessor :request_debug_allow

    def initialize(policy_identifier, policy_configuration)
      @roles = []
      @policy_identifier = policy_identifier
      @configuration = policy_configuration
      validate_bootstrap(policy_identifier, policy_configuration)
      setup
    end

    def requires_roles(roles)
      roles = [roles] if not roles.is_a?(Array)
      @roles = roles
    end

    def use_idm(idm)
      @idm = idm
    end

    def authorize(subject_identifier, requestor_identifier = nil, resource_identifier = nil, request = nil)
      result = translate_request(request)
      return result if result['status'] == 'fail'
      requested = result['data']['requested']

      validation_error = validate_authorization(subject_identifier, requestor_identifier, resource_identifier, requested)
      return validation_error if validation_error

      result = discover_entity(subject_identifier)
      error = result['data']['notifications'].first
      return fail(error, build_result(false, error, @idm)) if result['status'] == 'fail'

      result, message = apply_rule_set(subject_identifier, requestor_identifier, resource_identifier, requested, result['data']['subject_roles'], result['data']['attributes'])
      build_response(result, message)
    end

    protected

    def setup
    end

    def apply_rule_set(subject_identifier, requestor_identifier, resource_identifier, request, subject_roles, attributes)
      # override me
      true
    end

    def discover_entity(subject_identifier)
      subject_roles = discover_subject_roles(subject_identifier) if @idm
      return fail("Role missing") if not roles_present?(subject_roles, @roles)
      attributes = discover_subject_role_attributes(subject_identifier, subject_roles) if @idm
      success_data( { 'subject_roles' => subject_roles, 'attributes' => attributes } )

      rescue => ex
        return fail('Entity error (IDM)')
    end

    def discover_subject_roles(subject_identifier)
      subject_roles = @idm.get_roles(subject_identifier)
    end

    def discover_subject_role_attributes(subject_identifier, subject_roles)
      attributes = {}
      @roles.each do |role|
        result = @idm.get_attributes(subject_identifier, role)
        attributes[role] = result.nil? ? nil : result[role]
      end
      attributes
    end

    private

    def validate_bootstrap(policy_identifier, policy_configuration)
      valid_policy_identifier = valid_non_empty_string?(policy_identifier)
      valid_configuration = @configuration.is_a?(Hash)
      valid_rule_set = (self.class.name != 'SoarPl::AuthorizationPolicy')
      set_bootstrap_status(policy_identifier, policy_configuration, valid_configuration, valid_rule_set, valid_policy_identifier)

      return valid_configuration, valid_rule_set, valid_policy_identifier
    end

    def data_invalidated
      { 'dependencies' => 
        { 'configuration' => 'invalid',
          'policy_identifier' => 'invalid',
          'rule_set' => 'invalid' } }
    end      

    def set_bootstrap_status(policy_identifier, policy_configuration, valid_configuration, valid_rule_set, valid_policy_identifier)
      data = data_invalidated

      if (policy_identifier.nil?)
        @status = fail('no identifier provided')
      elsif (not valid_policy_identifier)
        @status = fail('invalid identifier provided')
      elsif policy_configuration.nil?
        @status = fail('no configuration provided')
      elsif not valid_configuration
        @status = fail('invalid configuration provided', data) 
      elsif not valid_rule_set
        # Must extend this class and provide a rule set in apply_rule_set(...)
        @status = fail('invalid rule set provided')
      else
        @status = success_data(data)
      end

      data['dependencies']['configuration'] = (valid_configuration ? 'valid' : 'invalid')
      data['dependencies']['rule_set'] = (valid_rule_set ? 'valid' : 'invalid')
      data['dependencies']['policy_identifier'] = (valid_policy_identifier ? 'valid' : 'invalid')      
    end

    def translate_request(request)
      requested = {}
      if request
        requested = request
        begin
          requested = JSON.parse(request) if not request.is_a?(Hash)
        rescue => ex
          return fail("Invalid request", build_result(false, "Invalid request", @idm))        
        end
      end
      success_data({'requested' => requested})
    end

    def validate_authorization(subject_identifier, requestor_identifier, resource_identifier, requested)
      return fail_invalid("resource identifier") if resource_identifier and (not valid_non_empty_string?(resource_identifier))
      return fail("Invalid request", build_result(false, "Invalid request", @idm)) if requested and (not requested.is_a?(Hash))
      return fail_invalid("requestor identifier") if requestor_identifier and (not valid_non_empty_string?(requestor_identifier))
      return fail_invalid("subject identifier") if subject_identifier.nil? or (subject_identifier and (not valid_non_empty_string?(subject_identifier)))
    end

    def build_response(result, message)
      return success_data(build_result(true, message, @idm)) if result
      success_data(build_result(false, message, @idm))
    end

    def fail_invalid(description)
      fail("Invalid #{description}", build_result(false, "Invalid #{description}", @idm))      
    end

    def valid_non_empty_string?(value)
      not (value.nil? or (not value.is_a?(String)) or (value.strip == ''))
    end

    def build_result(allow, message, idm)
      {'allowed' => allow, 'detail' => message, 'idm' => idm, 'rule_set' => self.class.name}
    end

    def roles_present?(subject_roles, required_roles)
      return true if required_roles.nil? or required_roles.empty?
      return false if subject_roles.nil?
      required_roles.each do |role|
        return false if not subject_roles.include?(role)
      end
      true
    end
  end
end

