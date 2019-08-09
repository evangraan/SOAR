require 'openssl'
require 'time'

require "smaak/version"
require "smaak/cavage_04"
require "smaak/adaptors/net_http_adaptor"
require "smaak/adaptors/rack_adaptor"
require "smaak/crypto"

module Smaak
  DEFAULT_TOKEN_LIFE = 2 unless defined? DEFAULT_TOKEN_LIFE; DEFAULT_TOKEN_LIFE.freeze

  @@adaptors = { Net::HTTPRequest => NetHttpAdaptor, Rack::Request => RackAdaptor}
 
  def self.headers_to_be_signed
    [ "x-smaak-recipient",
      "x-smaak-identifier",
      "x-smaak-route-info",
      "x-smaak-psk",
      "x-smaak-expires",
      "x-smaak-nonce",
      "x-smaak-encrypt" ]
  end

  def self.adaptors
    @@adaptors
  end

  def self.add_request_adaptor(request_clazz, adaptor_clazz)
    @@adaptors[request_clazz] = adaptor_clazz
  end

  def self.create_adaptor(request)
    @@adaptors.each do |r, a|
      return a.new(request) if request.is_a? r
    end
    raise ArgumentError.new("Unknown request class #{request.class}. Add an adaptor using Smaak.add_request_adaptor.")
  end

  def self.select_specification(adaptor, specification)
    raise ArgumentError.new("Adaptor must be provided") if adaptor.nil?
    return Cavage04.new(adaptor) if specification == Smaak::Cavage04::SPECIFICATION
    raise ArgumentError.new("Unknown specification")
  end

  def self.sign_authorization_headers(key, auth_message, adaptor, specification = Smaak::Cavage04::SPECIFICATION)
    specification = Smaak.select_specification(adaptor, specification)

    signature_headers = specification.compile_signature_headers(auth_message)
    signature_data = Smaak::Crypto.sign_data(signature_headers, key)
    signature = Smaak::Crypto.encode64(signature_data)
    specification.compile_auth_header(signature)
    specification.adaptor
  end

  def self.verify_authorization_headers(adaptor, pubkey)
    raise ArgumentError.new("Key is required") if pubkey.nil?
    signature_headers, signature = Smaak.get_signature_data_from_request(adaptor)
    if signature.nil?
      puts "[smaak error]: could not extract signature"
      return false
    end
    if signature_headers.nil?
      puts "[smaak error]: could not extract signature headers"
      return false
    end
    verified = Smaak::Crypto.verify_signature(signature, Smaak::Crypto.encode64(signature_headers), pubkey)
    puts "[smaak error]: verification of headers and signature using pubkey failed" unless verified
    verified
  end

  private

  def self.get_signature_data_from_request(adaptor, specification = Smaak::Cavage04::SPECIFICATION)
    specification = Smaak.select_specification(adaptor, specification)

    signature_headers = specification.extract_signature_headers
    signature = specification.extract_signature

    return signature_headers, Smaak::Crypto.decode64(signature)
  end
end

