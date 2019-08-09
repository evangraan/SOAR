require 'rack'
require 'soar_aspects'
require 'soar_lexicon'
require 'jsender'
require "soar_wadl_validation/version"

module SoarWadlValidation
  class Validator
    include Jsender

    attr_accessor :app

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      errors = validate(request)

      if not errors.nil?
        errors.push("Parameter specification: #{request.path}?wadl")
        error_data = fail(errors, 'Validation failed').to_json
        return [400, {"Content-Type" => "application/json"} , [error_data]]
      end

      @app.call(env)
    end

    private

    def validate(request)
      wadl = SoarLexicon::Lexicon::describe_resource(SoarAspects::Aspects::lexicon , request.path)
      return nil if wadl.nil?
      pattern = /wadl:param name=\"(?<name>\S+)\" type=\"xsd:(?<type>\S+)\" required=\"(?<required>\S+)\"/
      entries = wadl.scan(pattern)
      errors = []
      entries.each do |entry|
        if entry[2] == 'true'
          dictionary = extract_dictionary(request)
          errors << "Parameter '#{entry[0]}' is required" if not parameter_present?(dictionary, entry[0])
        end
        # if request.params[entry[0]]
        #   errors << "Parameter #{entry[0]} is not of type #{entry[1]}" if not request.params[entry[0]].class.is_a?(entry[1])
        # end
      end
      errors.empty? ? nil : errors
    end   

    def extract_dictionary(request)
      dictionary = {}
      dictionary = request.params
      begin
        dictionary.merge!(JSON.parse(request.body.string)) if request.body
      rescue
      end
      dictionary
    end

    def parameter_present?(dictionary, param)
      nested = param.include?('[') and param.include?(']')
      if not nested
        return not(dictionary[param].nil?)
      else
        key = param.split('[')[0]
        nested_key = param.split('[')[1].split(']')[0]
        return not(dictionary[key].nil? or dictionary[key][nested_key].nil?)
      end
      false
    end
  end
end
