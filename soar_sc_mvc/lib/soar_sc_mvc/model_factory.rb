require 'soar_configured_factory'

module SoarSc
  module Web
    module Models
      class ModelFactory < SoarConfiguredFactory::ConfiguredFactory
        def initialize(configuration)
          super(configuration)
          @path = ['providers']
        end
      end
    end
  end
end
