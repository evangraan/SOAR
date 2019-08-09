require 'erb'

module SoarSc
  module Web
    module Views
      module ERBLoader

        class ERBNamespace
          def initialize(hash)
            hash.each do |k, v|
              singleton_class.send(:define_method, k) { v }
            end
          end

          def get_binding
            binding
          end
        end

        def self.load(view, data)
          page = File.read("#{Dir.pwd}/lib/web/views/#{view}.erb.html")
          ns = ERBNamespace.new(data)
          ERB.new(page).result(ns.get_binding)
        end
      end
    end
  end
end
