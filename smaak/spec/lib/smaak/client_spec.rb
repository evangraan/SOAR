require './spec/spec_helper.rb'
require 'smaak'

describe Smaak::Client do
  before :all do
    @test_uri = "http://rubygems.org:80/gems/smaak"
    @test_encrypt = false
    @test_service_identifier = 'service-to-talk-to'
    @test_service_psk = 'testsharedsecret'
    @test_client_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_service_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_service_public_key = @test_service_private_key.public_key
    @test_data = {}
    @iut = Smaak::Client.new
    @test_identifier = 'test-client-1.cpt1.host-h.net'
    @test_route_info = 'identifier'
    @test_token_life = 5
    @iut.set_identifier(@test_identifier)
    @iut.set_private_key(@test_client_private_key)
    @iut.set_token_life(@test_token_life)
    @iut.add_association(@test_service_identifier, @test_service_public_key, @test_service_psk, @test_encrypt)

    @request = Net::HTTP::Post.new(@test_uri)
    @request.body = "body-data"
    @test_adaptor = Smaak::NetHttpAdaptor.new(@request)
  end

  context "when given an identifier" do
    it "should remember an identifier provided" do
      iut = Smaak::Client.new
      expect(iut.identifier).to eq(nil)
      iut.set_identifier(@test_identifier)
      expect(iut.identifier).to eq(@test_identifier)
    end

    it "should raise an ArgumentError if an identifier is not provided" do
      expect {
        @iut.set_identifier(nil)
      }.to raise_error ArgumentError, "Invalid identifier"
      expect {
        @iut.set_identifier("")
      }.to raise_error ArgumentError, "Invalid identifier"
      expect {
        @iut.set_identifier("  ")
      }.to raise_error ArgumentError, "Invalid identifier"
    end
  end

  context "when given an route information" do
    it "should remember a the route information provided" do
      iut = Smaak::Client.new
      expect(iut.route_info).to eq("")
      iut.set_route_info(@test_route_info)
      expect(iut.route_info).to eq(@test_route_info)
    end
  end

  context "when given no route information" do
    it "should remember empty route information" do
      iut = Smaak::Client.new
      iut.set_route_info(nil)
      expect(iut.route_info).to eq("")
    end
  end

  context "when initialized" do
    it "should have empty route information" do
      iut = Smaak::Client.new
      expect(iut.route_info).to eq("")
    end
  end

  context "when asked to sign a request destined for an associate" do
    it "should raise an ArgumentError if the associate is unknown" do
      expect{
        @iut.sign_request("unknown", nil)
      }.to raise_error ArgumentError, "Associate invalid"
      expect{
        @iut.sign_request(nil, nil)
      }.to raise_error ArgumentError, "Associate invalid"
    end

    it "should raise an ArgumentError if an adaptor was not provided" do
      expect {
        @iut.sign_request(@test_service_identifier, nil)
      }.to raise_error ArgumentError, "Invalid adaptor"
    end

    it "should create a new auth message using the associate details" do
      expect(Smaak::AuthMessage).to receive(:create).with(@test_service_public_key.export, @test_service_psk, @test_token_life, @test_identifier, @test_route_info, @test_encrypt)
      expect {
        @iut.set_route_info(@test_route_info)
        @iut.sign_request(@test_service_identifier, @test_adaptor)
      }.to raise_error NoMethodError
    end

    it "should encrypt the request body if the associate is configured for encryption" do
      @iut.add_association('encrypted', @test_service_public_key, @test_service_psk, true)
      expect(Smaak::Crypto).to receive(:encrypt).with(@test_adaptor.body, @test_service_public_key).and_return(@test_adaptor.body)
      @iut.sign_request('encrypted', @test_adaptor)
    end

    it "should not encrypt the request body if the associate is not configure for encryption" do
      expect(Smaak::Crypto).not_to receive(:encrypt)
      @iut.sign_request(@test_service_identifier, @test_adaptor)
    end

    it "should sign the message" do
      expect(Smaak).to receive(:sign_authorization_headers)
      @iut.sign_request(@test_service_identifier, @test_adaptor)
    end

    it "should return the adaptor with the signed request" do
      expect(@iut.sign_request(@test_service_identifier, @test_adaptor)).to eq(@test_adaptor)
    end 
  end

  context "when asked to help the developer by providing GET and POST requests given an associate, URI, body, ssl and ssl verify option" do
    it "should compile a Net::HTTP request" do
      url = URI.parse(@test_uri)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port)
      expect {
        @iut.get(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should set the method to GET if requested" do
      url = URI.parse(@test_uri)
      expect(Net::HTTP::Get).to receive(:new).with(url.to_s)
      expect {
        @iut.get(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should set the method to POST if requested" do
      url = URI.parse(@test_uri)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s)
      expect {
        @iut.post(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should set use_ssl appropriately" do
      url = URI.parse(@test_uri)
      mock_http = double(Net::HTTP)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(mock_http).to receive(:use_ssl=).with(false)
      expect {
        @iut.get(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should configure ssl verification appropriately" do
      url = URI.parse(@test_uri)
      mock_http = double(Net::HTTP)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(mock_http).to receive(:use_ssl=).with(false)
      expect(mock_http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      expect {
        @iut.get(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should set the body appropriately" do
      url = URI.parse(@test_uri)
      mock_req = double(Net::HTTP::Post)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s).and_return(mock_req)
      expect(mock_req).to receive(:body=).with(@test_body)
      expect {
        @iut.post(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
      }.to raise_error
    end

    it "should connect using the URI provided" do
      url = URI.parse(@test_uri)
      mock_http = Net::HTTP.new(url.host, url.port)
      mock_req = Net::HTTP::Post.new(url.to_s)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s).and_return(mock_req)
      mock_response = ""
      allow(mock_response).to receive(:code).and_return "200"
      expect(mock_http).to receive(:request).with(mock_req).and_return(mock_response)
      @iut.post(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
    end

    it "should decrypt the response body if the request was encrypted" do
      @iut.add_association('encrypted', @test_service_public_key, @test_service_psk, true)
      url = URI.parse(@test_uri)
      mock_http = Net::HTTP.new(url.host, url.port)
      mock_req = Net::HTTP::Post.new(url.to_s)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s).and_return(mock_req)
      mock_response = ""
      expect(mock_response).to receive(:body).and_return ""
      allow(mock_response).to receive(:code).and_return "200"
      expect(mock_response).to receive(:body=)
      expect(mock_http).to receive(:request).with(mock_req).and_return(mock_response)
      expect(Smaak::Crypto).to receive(:encrypt).and_return ""
      expect(Smaak::Crypto).to receive(:decrypt).with("", @iut.key)
      @iut.post('encrypted', @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
    end

    it "should decrypt the response body only if the response code is a 200 class code (2XX)" do
      @iut.add_association('encrypted', @test_service_public_key, @test_service_psk, "true")
      url = URI.parse(@test_uri)
      mock_http = Net::HTTP.new(url.host, url.port)
      mock_req = Net::HTTP::Post.new(url.to_s)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s).and_return(mock_req)
      mock_response = ""
      expect(mock_response).to receive(:body).and_return ""
      allow(mock_response).to receive(:code).and_return "200"
      expect(mock_response).to receive(:body=)
      expect(mock_http).to receive(:request).with(mock_req).and_return(mock_response)
      expect(Smaak::Crypto).to receive(:encrypt).and_return ""
      expect(Smaak::Crypto).to receive(:decrypt).with("", @iut.key)

      @iut.post('encrypted', @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)
    end

    it "should return the response" do
      url = URI.parse(@test_uri)
      mock_http = Net::HTTP.new(url.host, url.port)
      mock_req = Net::HTTP::Post.new(url.to_s)
      expect(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(mock_http)
      expect(Net::HTTP::Post).to receive(:new).with(url.to_s).and_return(mock_req)
      mock_response = "response"
      allow(mock_response).to receive(:code).and_return "200"
      expect(mock_http).to receive(:request).with(mock_req).and_return mock_response
      expect(@iut.post(@test_service_identifier, @test_uri, @test_body, false, OpenSSL::SSL::VERIFY_NONE)).to eql("response")
    end
  end
end
