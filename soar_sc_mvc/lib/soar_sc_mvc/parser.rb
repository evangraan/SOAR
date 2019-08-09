module SoarSc
  module Web
    class Parser
      def self.parseIntoParams(request)
        rx = extract_request_parameters(request)
        return {} if not rx
        enumerate_parameters(rx)
      end

      def self.ensure_quoted(value)
        is_quoted?(value) ? value : "\"#{value}\""
      end
        
      def self.ensure_not_quoted(value)
        is_quoted?(value) ? value[1..-2] : value
      end

      private

      def self.is_quoted?(param)
        double = (param[0] == '"') and (param[param.size-1] == '"')
        single = (param[0] == "'") and (param[param.size-1] == "'")
        single or double
      end

      def self.extract_request_parameters(request)
        rx = request.env['rack.request.form_vars'] || ""
        rx = ((request.body.is_a? Rack::Lint::InputWrapper) ? request.body.gets : request.body) if rx == ""
        rx = request.url.split('?')[1] if (request.url) and (not request.url.split('?').nil?) and (rx == "")
        rx
      end

      def self.enumerate_parameters(rx)
        params = {}
        rx.split('&').each do |keyvalue|
          params = append_parameter(params, keyvalue)
        end
        params
      end

      def self.append_parameter(params, keyvalue)
        key = keyvalue.split('=')[0]
        value = keyvalue.split('=')[1]
        params[key] = value.nil? ? nil : CGI::unescape(value)
        params
      end
    end
  end
end
