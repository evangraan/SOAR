require 'jsender'

module SoarSc
  module Web
    module Views
      module Default
        include Jsender

        def self.render(http_code, body)
          [http_code, {"Content-Type" => "text/html"}, [body]]
        end

        def self.not_found
          [404, {}, ["404 - Not found"]]
        end

        def self.not_authenticated
          [401, {}, ["401 - Not authenticated"]]
        end

        def self.not_authorized
          [403, {}, [" 403 - Not authorized"]]
        end

        def self.not_valid(errors)
          [400, {"Content-Type" => "application/json"} , errors]
        end

        def self.error(ex)
          if ex.is_a?(Exception)
            body = "#{ex.class}: #{ex.message}"
            body = body + ":\n\t" + ex.backtrace.join("\n\t") if ENV['RACK_ENV'] == 'development'
          else
            body = ex.to_s
          end
          [500, {"Content-Type" => "text/html"}, [body]]
        end        
      end
    end
  end
end
