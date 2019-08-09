require 'smaak'
require 'uri'

module Smaak
  class RackAdaptor
    attr_reader :request

    def initialize(request)
      raise ArgumentError.new("Must provide a Rack::Request") unless request.is_a? Rack::Request
      @request = request
    end

    def header(header)
      raise ArgumentError.new("Header must be a non-blank string") unless Smaak::Utils.non_blank_string?(header)
      match_header(header)
    end
  
    def method
      @request.env["REQUEST_METHOD"]
    end

    def path
      @request.env["PATH_INFO"]
    end

    def body
      @request.body
    end

    private

    def match_header(header)
      return content_length if header == "content-length"
      return @request.env["HTTP_HOST"].split(':')[0] if (not @request.env["HTTP_HOST"].nil?) and (header == "host")
      return @request.env["REQUEST_METHOD"] if header == "request-method"
      return @request.env["HTTP_#{header.upcase.gsub("-", "_")}"]
    end

    def content_length
      value = @request.env["CONTENT_LENGTH"]
      value = 0 if value.nil?
      return value
    end
  end
end
