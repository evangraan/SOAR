module SoarSc
  module Web
    module Models
      class ConfiguredModel
        attr_accessor :configuration
        attr_accessor :dependencies

        def initialize(configuration)
          @configuration = configuration
          @dependencies = SoarSc::dependencies
        end

        def auditing
          SoarAspects::Aspects::auditing
        end
      end
    end
  end
end
