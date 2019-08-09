require './spec/spec_helper.rb'
require 'net/http'

describe Smaak do
  before :all do
    @test_server_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_server_public_key = @test_server_private_key.public_key
    @request = Net::HTTP::Post.new("http://rubygems.org:80/gems/smaak")
    @request.body = "body-data"
    @test_nonce = 1234567890
    @test_expires = Time.now.to_i + 5
    @test_psk = "testpresharedkey"
    @test_identifier = 'test-service-1.cpt1.host-h.net'
    @test_route_info = 'identifier'
    @test_recipient = @test_server_public_key.export
    @test_encrypt = true
    @auth_message = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, @test_encrypt)
    @adaptor = Smaak.create_adaptor(@request)
    @mock_specification = Smaak::Cavage04.new(@adaptor)
  end

  context "when loaded" do
    it "should specify a default token life" do
     expect(Smaak::DEFAULT_TOKEN_LIFE).to eq(2)
    end
  end

  context "when asked which headers should be signed" do
    it "should list all the smaak header extensions" do
      expect(Smaak.headers_to_be_signed.include?("x-smaak-recipient")).to eql(true)
      expect(Smaak.headers_to_be_signed.include?("x-smaak-identifier")).to eql(true)
      expect(Smaak.headers_to_be_signed.include?("x-smaak-psk")).to eql(true)
      expect(Smaak.headers_to_be_signed.include?("x-smaak-expires")).to eql(true)
      expect(Smaak.headers_to_be_signed.include?("x-smaak-nonce")).to eql(true)
      expect(Smaak.headers_to_be_signed.include?("x-smaak-encrypt")).to eql(true)
    end
  end

  context "when told about a new request adaptor" do
    it "should remember the adaptor class associated with the request class" do
      Smaak.add_request_adaptor(Integer, String)
      expect(Smaak.adaptors[Integer]).to eql(String)
    end
  end

  context "when asked to create a request adaptor" do
    it "should raise an ArgumentError if the request type does not have an adaptor configured" do
      expect {
        Smaak.create_adaptor(0.1)
      }.to raise_error ArgumentError, "Unknown request class Float. Add an adaptor using Smaak.add_request_adaptor."
    end

    it "should create a new instance of the adaptor class specified in the request adaptor dictionary" do
      adaptor = Smaak.create_adaptor(Net::HTTP::Post.new("http://rubygems.org:80/gems/smaak"))
      expect(adaptor.is_a? Smaak::NetHttpAdaptor).to eql(true)
    end
  end

  context "when asked to select a header signature specification" do
    it "should raise an ArgumentError if the specification is unknown" do
      expect {
        Smaak.select_specification(@adaptor, "unknown specification")
      }.to raise_error ArgumentError, "Unknown specification"
    end

    it "should return an instance of a known specification" do
      expect(Smaak.select_specification(@adaptor, Smaak::Cavage04::SPECIFICATION).is_a?(Smaak::Cavage04)).to eql(true)
    end

    it "should raise an ArgumentError if the adaptor specified is nil" do
      expect {
        Smaak.select_specification(nil, Smaak::Cavage04::SPECIFICATION)
      }.to raise_error ArgumentError, "Adaptor must be provided"
    end
  end

  context "when asked to sign authorization headers given a key, auth_message, request adaptor and specification" do
    it "should select the requested specification" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      Smaak.sign_authorization_headers(@test_server_private_key, @auth_message, @adaptor, Smaak::Cavage04::SPECIFICATION)
    end

    it "should compile the signature header from the auth_message using the specification" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(@mock_specification).to receive(:compile_signature_headers).with(@auth_message).and_return "headers"
      Smaak.sign_authorization_headers(@test_server_private_key, @auth_message, @adaptor, Smaak::Cavage04::SPECIFICATION)
    end

    it "should sign the signature headers using the key" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(@mock_specification).to receive(:compile_signature_headers).with(@auth_message).and_return "headers"
      expect(Smaak::Crypto).to receive(:sign_data).with("headers", @test_server_private_key).and_return("signed headers")
      Smaak.sign_authorization_headers(@test_server_private_key, @auth_message, @adaptor, Smaak::Cavage04::SPECIFICATION)
    end

    it "should compile an auth header using the signature as the signature data base 64 encoded" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(@mock_specification).to receive(:compile_signature_headers).with(@auth_message).and_return "headers"
      expect(Smaak::Crypto).to receive(:sign_data).with("headers", @test_server_private_key).and_return("signed headers")
      expect(@mock_specification).to receive(:compile_auth_header).with(Base64.strict_encode64("signed headers"))
      Smaak.sign_authorization_headers(@test_server_private_key, @auth_message, @adaptor, Smaak::Cavage04::SPECIFICATION)
    end

    it "should return the adapter" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(Smaak.sign_authorization_headers(@test_server_private_key, @auth_message, @adaptor, Smaak::Cavage04::SPECIFICATION)).to eql(@adaptor)
    end
  end

  context "when asked if signed authorization headers are ok given a public key" do
    it "should select the requested specification" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect {
        Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)
      }.to raise_error
    end

    it "should extract the signature headers using the specification" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(@mock_specification).to receive(:extract_signature_headers).and_return "headers"
      expect {
        Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)
      }.to raise_error
    end

    it "should extract the signature using the specification" do
      expect(Smaak::Cavage04).to receive(:new).and_return(@mock_specification)
      expect(@mock_specification).to receive(:extract_signature_headers).and_return "headers"
      expect(@mock_specification).to receive(:extract_signature).and_return Base64.strict_encode64("signature")
      Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)
    end

    it "should return false if the signature is nil" do
      expect(Smaak).to receive(:get_signature_data_from_request).with(@adaptor).and_return(["headers", nil])
      expect(Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)).to eql(false)
    end

    it "should return false if the signature headers are nil" do
      expect(Smaak).to receive(:get_signature_data_from_request).with(@adaptor).and_return([nil, "signature"])
      expect(Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)).to eql(false)
    end

    it "should raise an ArgumentError if the public key is nil" do
      expect {
        Smaak.verify_authorization_headers(@adaptor, nil)
      }.to raise_error ArgumentError, "Key is required"
    end

    it "should verify the signature using the signature headers base 64 encoded, with the public key. I.e. can I produce the same signature?" do
      expect(Smaak).to receive(:get_signature_data_from_request).with(@adaptor).and_return(["headers", "signature"])
      expect(Smaak::Crypto).to receive(:verify_signature).with("signature", Smaak::Crypto.encode64("headers"), @test_server_public_key).and_return true
      Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)
    end

    it "should return false if verification fails" do
      expect(Smaak).to receive(:get_signature_data_from_request).with(@adaptor).and_return(["headers", "signature"])
      expect(Smaak::Crypto).to receive(:verify_signature).with("signature", Smaak::Crypto.encode64("headers"), @test_server_public_key).and_return false
      expect(Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)).to eql(false)
    end

    it "should return true if verification succeeds" do
      expect(Smaak).to receive(:get_signature_data_from_request).with(@adaptor).and_return(["headers", "signature"])
      expect(Smaak::Crypto).to receive(:verify_signature).with("signature", Smaak::Crypto.encode64("headers"), @test_server_public_key).and_return true
      expect(Smaak.verify_authorization_headers(@adaptor, @test_server_public_key)).to eql(true)
    end
  end
end
