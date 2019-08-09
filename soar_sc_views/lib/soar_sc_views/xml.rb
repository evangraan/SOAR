module SoarSc
  module Web
    module Views
      module XML
        def self.render(http_code, body)
          [http_code, {"Content-Type" => "application/xml"}, [body]]
        end

        def self.not_found
          [404, "", []]
        end

        def self.error
          body = ex.message
          [500, {"Content-Type" => "application/xml"}, [body]]
        end
      end
    end
  end
end

