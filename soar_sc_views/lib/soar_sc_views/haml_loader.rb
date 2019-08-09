require 'haml'

module SoarSc
  module Web
    module Views
      module HamlLoader
        def self.load(view, data)
          page = File.read("#{Dir.pwd}/lib/web/views/#{view}.haml")
          Haml::Engine.new(page).render(Object.new, data)
        end
      end
    end
  end
end
