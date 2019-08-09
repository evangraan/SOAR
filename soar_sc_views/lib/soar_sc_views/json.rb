require 'json'

module SoarSc
  module Web
    module Views
      module JSON
        def self.render(http_code, body)
          data = SoarSc::Web::Views::JSON::is_json?(body) ? body : ::JSON.generate(body)
          [http_code, {"Content-Type" => "application/json"}, [data]]
        end

        def self.not_found
          [404, {}, []]
        end

        def self.error
          body = ex.message
          [500, {"Content-Type" => "application/json"}, [::JSON.generate(body)]]
        end

        def self.is_json?(data)
          begin
            ::JSON.parse(data)
            return true
          rescue => ex
            return false
          end
        end
      end
    end
  end
end
