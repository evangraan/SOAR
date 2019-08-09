require "soar_aspects/version"

module SoarAspects
  class Aspects
    attr_reader :app

    @@configuration = nil
    @@signed_routes = nil
    @@auditing = nil
    @@lexicon = nil

    def self.configuration=(configuration)
      @@configuration = configuration
    end

    def self.configuration
      @@configuration
    end

    def self.signed_routes=(signed_routes)
      @@signed_routes = signed_routes
    end

    def self.signed_routes
      @@signed_routes
    end

    def self.auditing=(auditing)
      @@auditing = auditing
    end

    def self.auditing
      @@auditing
    end

    def self.lexicon=(lexicon)
      @@lexicon = lexicon
    end

    def self.lexicon
      @@lexicon
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      env['configuration'] = @@configuration
      env['signed_routes'] = @@signed_routes
      env['auditing'] = @@auditing
      env['lexicon'] = @@lexicon
      @app.call(env)
    end
  end
end