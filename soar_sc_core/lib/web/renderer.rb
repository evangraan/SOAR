Dir["web/views/*.rb"].each {|file| require file }

module SoarSc
  module Web
    class Renderer
      def render_view(detail, http_code, body)
        if detail['view']['renderer'] == 'haml'
          SoarSc::Web::Views::Default.render(http_code, SoarSc::Web::Views::HamlLoader::load(detail['view']['name'], body))
        elsif detail['view']['renderer'] == 'erb'
          SoarSc::Web::Views::Default.render(http_code, SoarSc::Web::Views::ERBLoader::load(detail['view']['name'], body))
        elsif detail['view']['renderer'] == 'html'
          SoarSc::Web::Views::Default.render(http_code, body)
        elsif detail['view']['renderer'] == 'json'
          SoarSc::Web::Views::JSON.render(http_code, body)
        elsif detail['view']['renderer'] == 'xml'
          SoarSc::Web::Views::XML.render(http_code, body)
        else
          Object::const_get(detail['view']['renderer']).new(@configuration).render(http_code, body)
        end
      end      
    end
  end
end