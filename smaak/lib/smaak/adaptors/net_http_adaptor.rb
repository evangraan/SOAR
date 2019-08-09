require 'smaak'
require 'smaak/utils'
require 'uri'

module Smaak
  class NetHttpAdaptor
    attr_reader :request

    def initialize(request)
      raise ArgumentError.new("Must provide a Net::HTTPRequest") unless request.is_a? Net::HTTPRequest
      @request = request
    end

    def set_header(header, value)
      raise ArgumentError.new("Header must be a non-blank string") unless Smaak::Utils.non_blank_string?(header)
      @request[header] = value
    end

    def each_header(&block)
      @request.each_header(&block)
    end

    def host
      URI.parse(@request.path).host
    end

    def path
      URI.parse(@request.path).path
    end

    def method
      @request.method
    end

    def body
      @request.body
    end

    def body=(body)
      @request.body = body
    end
  end
end
