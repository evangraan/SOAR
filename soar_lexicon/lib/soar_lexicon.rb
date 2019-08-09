require "soar_lexicon/version"
require 'wadling'
require 'rack'

module SoarLexicon
  class Lexicon
    WADL_XSL = "/wadl/wadl.xsl" if not defined? WADL_XSL; WADL_XSL.freeze
    attr_reader :app
    
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      return respond(SoarLexicon::Lexicon::describe(env['lexicon'])) if Regexp.new('/lexicon').match(request.path)
      return respond(SoarLexicon::Lexicon::describe_resource(env['lexicon'], request.path)) if request.env['QUERY_STRING'] == 'wadl'
      app.call(env)
    end

    def self.describe(lexicon)
      return nil if lexicon.nil?
      translator = Wadling::LexiconTranslator.new(SoarLexicon::Lexicon::WADL_XSL)
      translator.translate_resources_into_wadl(lexicon)
    end

    def self.describe_resource(lexicon, route)
      return nil if lexicon.nil? or lexicon[route].nil?
      translator = Wadling::LexiconTranslator.new(SoarLexicon::Lexicon::WADL_XSL)
      data = {}
      data[route] = lexicon[route]
      translator.translate_resources_into_wadl(data)
    end    

    private

    def respond(content)
      [200, {"Content-Type" => "application/xml"}, [content]]
    end
  end
end
