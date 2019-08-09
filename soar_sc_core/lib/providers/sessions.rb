module SoarSc
  module Providers
    class Sessions
      def bootstrap_sessions(stack)
        validate_session_configuration(SoarSc::environment)

        if 'true' == SoarSc::environment['USE_SESSIONS'] then
          stack.use Rack::Session::Cookie, key: SoarSc::environment['SESSION_KEY'], secret: SoarSc::environment['SESSION_SECRET']
        else
          SoarSc.auditing.debug('Not using sessions', SoarSc::startup_flow_id)
        end
      end

      private

      def validate_session_configuration(environment)
        validate_session_use(environment['USE_SESSIONS']) if not environment['USE_SESSIONS'].nil?
        validate_session_key(environment['SESSION_KEY']) if 'true' == environment['USE_SESSIONS']
        validate_session_secret(environment['SESSION_SECRET']) if 'true' == environment['USE_SESSIONS']
      end

      def validate_session_use(value)
        raise ArgumentError.new "Undefined USE_SESSIONS value" if value.nil? or (value.strip == '')
        raise ArgumentError.new "Invalid USE_SESSIONS value" if not ['true','false'].include? value
      end

      def validate_session_key(value)
        raise ArgumentError.new "Missing session key SESSION_KEY" if value.nil? or (value.strip == '')
        raise ArgumentError.new "Invalid session key SESSION_KEY" if /[^!#$%&'*+\-.0-9A-Z^_`a-z|~]+/.match(value)
      end

      def validate_session_secret(value)
        raise ArgumentError.new "Missing session secret SESSION_SECRET" if value.nil? or (value.strip == '')
        raise ArgumentError.new "Invalid session secret SESSION_SECRET" if value.length < 32
      end
    end
  end
end
