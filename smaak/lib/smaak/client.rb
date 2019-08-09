require 'uri'
require 'smaak.rb'
require 'smaak/associate.rb'
require 'smaak/auth_message.rb'

module Smaak
  class Client < Associate
    attr_reader :identifier
    attr_reader :route_info

    def initialize
      super
      set_route_info("")
    end

    def set_private_key(key)
      set_key(key)
    end

    def set_identifier(identifier)
      raise ArgumentError.new("Invalid identifier") unless Smaak::Utils.non_blank_string?(identifier)
      @identifier = identifier
    end

    def set_route_info(route_info)
      @route_info = route_info
      @route_info ||= ""
    end

    def sign_request(associate_identifier, adaptor)
      raise ArgumentError.new("Associate invalid") unless validate_associate(associate_identifier)
      associate = @association_store[associate_identifier]
      raise ArgumentError.new("Invalid adaptor") if adaptor.nil?
      auth_message = Smaak::AuthMessage.create(associate['public_key'].export, associate['psk'], @token_life, @identifier, @route_info, associate['encrypt'])
      adaptor.body = Smaak::Crypto.encrypt(adaptor.body, associate['public_key']) if auth_message.encrypt
      Smaak.sign_authorization_headers(@key, auth_message, adaptor, Smaak::Cavage04::SPECIFICATION)
    end

    def get(identifier, uri, body, ssl = false, ssl_verify = OpenSSL::SSL::VERIFY_PEER)
      connect(Net::HTTP::Get, identifier, uri, body, ssl, ssl_verify)
    end

    def post(identifier, uri, body, ssl = false, ssl_verify = OpenSSL::SSL::VERIFY_PEER)
      connect(Net::HTTP::Post, identifier, uri, body, ssl, ssl_verify)
    end

    private

    def validate_associate(associate_identifier)
      return false if associate_identifier.nil?
      return false if @association_store[associate_identifier].nil?
      true
    end

    def connect(connector, identifier, uri, body, ssl, ssl_verify)
      url, http = build_http(uri, ssl, ssl_verify)
      req = build_request(connector, url, body, identifier)
      request_and_respond(http, req, identifier)

      rescue => ex
        puts "[smaak error] request to associate failed"
        throw ex
    end

    def build_http(uri, ssl, ssl_verify)
      url = URI.parse(uri)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = ssl
      http.verify_mode = ssl_verify
      return url, http
    end  

    def build_request(connector, url, body, identifier)
      req = connector.new(url.to_s)
      req.body = body
      adaptor = Smaak.create_adaptor(req)
      (sign_request(identifier, adaptor)).request      
    end

    def request_and_respond(http, req, identifier)
      response = http.request(req)
      response.body = Smaak::Crypto.decrypt(response.body, @key) if encrypt_associate?(identifier) and response.code[0] == '2'
      puts "[smaak error]: response from #{identifier} was #{response.code}" unless response.code[0] == '2'
      response
    end

    def encrypt_associate?(identifier)
      return false if identifier.nil?
      return false if @association_store[identifier].nil?
      return true if @association_store[identifier]["encrypt"] == true
      return true if @association_store[identifier]["encrypt"].to_s.downcase == "true"
      false
    end
  end
end
