require 'smaak'

module Smaak
  class Cavage04
    SPECIFICATION = "https://datatracker.ietf.org/doc/draft-cavage-http-signatures/04/" unless defined? SPECIFICATION; SPECIFICATION.freeze
    attr_reader :adaptor
    attr_reader :headers_to_be_signed

    def initialize(adaptor)
      raise ArgumentError.new("Must provide a valid request adaptor") if adaptor.nil?
      @adaptor = adaptor
      @headers_to_be_signed = Smaak::Cavage04.headers_to_be_signed + Smaak.headers_to_be_signed
    end
  
    def self.headers_to_be_signed
      [ "(request-target)",
        "host",
        "date",
        "digest",
        "content-length" ]
    end

    def compile_auth_header(signature)
      raise ArgumentError.new("invalid signature") unless Smaak::Utils.non_blank_string?(signature)
      ordered_headers = ""
      @adaptor.each_header do |header, _value|
        ordered_headers = "#{ordered_headers} #{header}" if @headers_to_be_signed.include?(header)
      end
      ordered_headers = ordered_headers[1..ordered_headers.size]
      @adaptor.set_header("authorization", "Signature keyId=\"rsa-key-1\",algorithm=\"rsa-sha256\", headers=\"#{ordered_headers}\", signature=\"#{signature}\"")
    end

    def compile_signature_headers(auth_message)
      set_adaptor_headers(auth_message)

      signature_headers = ""
      @adaptor.each_header do |header, value|
        signature_headers = append_header(signature_headers, "#{header}: #{value}") if @headers_to_be_signed.include? header
      end
      signature_headers = prepend_header("(request-target)", "#{@adaptor.method.downcase} #{@adaptor.path}", signature_headers)
    end

    def extract_signature_headers
      @adaptor.header("authorization") =~ /headers=\"([^"]*)\",/
      headers_order = $1.split(' ')
  
      signature_headers = ""
      headers_order.each do |header|
        signature_headers = append_header(signature_headers, "#{header}: #{@adaptor.header(header)}")
      end
      signature_headers = prepend_header("(request-target)", "#{@adaptor.method.downcase} #{@adaptor.path}", signature_headers)
    end

    def extract_signature
      @adaptor.header("authorization") =~ /signature=\"([^"]*)\"/
      $1
    end

    private

    def gmt_now
      Time.now.gmtime.to_s.gsub("UTC", "GMT")
    end

    def append_header(header_list, header)
      "#{header_list}\n#{header}"
    end

    def prepend_header(header, value, signature_headers)
      "#{header}: #{value}#{signature_headers}"
    end

    def set_adaptor_headers(auth_message)
      body = @adaptor.body.nil? ? "" : @adaptor.body
      @adaptor.set_header("authorization", "")
      @adaptor.set_header("host", "#{@adaptor.host}")
      @adaptor.set_header("date", "#{gmt_now}")
      @adaptor.set_header("digest", "SHA-256=#{Digest::SHA256.hexdigest(body)}")
      @adaptor.set_header("x-smaak-recipient", "#{Smaak::Crypto.encode64(auth_message.recipient)}")
      @adaptor.set_header("x-smaak-identifier", "#{auth_message.identifier}")
      @adaptor.set_header("x-smaak-route-info", "#{auth_message.route_info}")
      @adaptor.set_header("x-smaak-psk", "#{auth_message.psk}")
      @adaptor.set_header("x-smaak-expires", "#{auth_message.expires}")
      @adaptor.set_header("x-smaak-nonce", "#{auth_message.nonce}")
      @adaptor.set_header("x-smaak-encrypt", "#{auth_message.encrypt}")
      @adaptor.set_header("content-type", "text/plain")
      @adaptor.set_header("content-length", "#{body.size}")
    end
  end
end
