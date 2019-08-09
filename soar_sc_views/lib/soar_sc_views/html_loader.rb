module SoarSc
  module Web
    module Views
      module HtmlLoader      
        def self.render(view)
          body = load_view_if_exists('', "#{Dir.pwd}/lib/web/views/#{view}.html")
          body = load_view_if_exists(body, "#{Dir.pwd}/#{view}.html")
          [200, {"Content-Type" => "text/html"}, [body]]
        end

        private

        def self.load_view_if_exists(body, filename)
          File.exists?(filename) ? File.read(filename) : body
        end
      end
    end
  end
end