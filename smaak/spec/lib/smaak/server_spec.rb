require './spec/spec_helper.rb'
require 'smaak'

def mock_auth_message(env)
  request = Rack::Request.new(env)
  adaptor = Smaak.create_adaptor(request)
  @iut.build_auth_message_from_request(adaptor)
end

describe Smaak::Server do
  before :all do
    @iut = Smaak::Server.new
    @iut.set_token_life(2)
    @test_nonce = "1234567890"
    @test_server_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_psk = "testpresharedkey"
    @test_server_public_key = @test_server_private_key.public_key
    @test_identifier = 'test-service-1.cpt1.host-h.net'
    @test_route_info = 'identifier'
    @message = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, Time.now.to_i, @test_psk, @test_server_public_key.export, false)
    @iut.add_association(@test_identifier, @test_server_public_key, @test_psk, false)
    @iut.set_public_key(@test_server_public_key)
    @iut.set_private_key(@test_server_private_key)
  end

  before :each do
    @iut.nonce_store[@test_nonce] = nil
    expect(@iut.nonce_store[@test_nonce]).to eq(nil)

    @test_expires = "#{Time.now.to_i + 5}"
    @env = {"CONTENT_LENGTH" => "25", "REQUEST_METHOD" => "POST", "PATH_INFO" => "/gems/smaak", "HTTP_X_SMAAK_ENCRYPT" => "false", "HTTP_X_SMAAK_RECIPIENT" => Base64.strict_encode64(@test_server_public_key.export), "HTTP_X_SMAAK_IDENTIFIER" => @test_identifier, "HTTP_X_SMAAK_ROUTE_INFO" => @test_route_info, "HTTP_X_SMAAK_NONCE" => @test_nonce, "HTTP_X_SMAAK_EXPIRES" => @test_expires, "HTTP_X_SMAAK_PSK" => Smaak::Crypto.obfuscate_psk(@test_psk) }
    @auth_message = mock_auth_message(@env)
  end

  context "when initialized" do
    it "should have a nonce store" do
      expect(@iut.nonce_store.class).to eq(Persistent::Cache)
    end

    it "should not know its own public key" do
      iut = Smaak::Server.new
      expect(iut.key).to eq(nil)
    end

    it "should not know its own private key" do
      iut = Smaak::Server.new
      expect(iut.private_key).to eq(nil)
    end
  end

  context "when given a private key" do
    it "should remember its private key" do
      @iut.set_private_key(@test_server_private_key)
      expect(@iut.private_key).to eql(@test_server_private_key)
    end

    it "should validate and adapt the key before assignment" do
      expect(@iut).to receive(:adapt_rsa_key).with(@test_server_private_key)
      @iut.set_private_key(@test_server_private_key)
    end
  end

  context "when given a public key" do
    it "should remember its public key" do
      @iut.set_key(@test_server_public_key)
      expect(@iut.key).to eql(@test_server_public_key)
    end

    it "should validate and adapt the key before assignment" do
      expect(@iut).to receive(:adapt_rsa_key).with(@test_server_public_key)
      @iut.set_private_key(@test_server_public_key)
    end
  end

  context "when preventing replay attacks" do
    it "should forget about nonces older than token_life" do
      nonces = @iut.nonce_store
      nonces[@test_nonce] = 1
      expect(nonces[@test_nonce]).to eq(1)
      sleep @iut.token_life
      expect(nonces[@test_nonce]).to eq(nil)
    end

    it "should remember nonces younger than token_life" do
      nonces = @iut.nonce_store
      nonces[@test_nonce] = 1
      expect(nonces[@test_nonce]).to eq(1)
      sleep @iut.token_life - 1
      expect(nonces[@test_nonce]).to eq(1)
    end
  end

  context "when asked if a message is unique" do
    it "should store a nonce once it has seen it" do
      @iut.auth_message_unique?(@message)
      expect(@iut.nonce_store[@test_nonce]).to eq(1)
    end

    it "should return true if the message nonce was not seen in the last token_life period" do
      expect(@iut.auth_message_unique?(@message)).to eq(true)
    end

    it "should return false if the message was seen in the last token_life period" do
      expect(@iut.auth_message_unique?(@message)).to eq(true)
      expect(@iut.auth_message_unique?(@message)).to eq(false)
    end
  end

  context "when asked to build an AuthMessage from a request received" do
    it "should decode the x-smaak-recipient header using base64 to obtain the recipient publc key" do
      expect(@auth_message.recipient).to eql(@test_server_public_key.export)
    end

    it "should set the psk to the x-smaak-psk header value" do
      expect(@auth_message.psk).to eql(Smaak::Crypto.obfuscate_psk(@test_psk))
    end

    it "should set expires to the x-smaak-expires header value" do
      expect(@auth_message.expires).to eql(@test_expires)
    end

    it "should set the identifier to the x-smaak-identifier header value" do
      expect(@auth_message.identifier).to eql(@test_identifier)
    end

    it "should set the route-info to the x-smaak-route-info header value" do
      expect(@auth_message.route_info).to eql(@test_route_info)
    end

    it "should set the nonce to the x-smaak-nonce header value" do
      expect(@auth_message.nonce).to eql(@test_nonce)
    end

    it "should return the auth_message" do
      expect(@auth_message.is_a?(Smaak::AuthMessage)).to eql(true)
    end
  end

  context "when asked to verify an auth message" do
    it "should return false if the auth message is not unique" do
      @iut.nonce_store[@test_nonce] = 1
      expect(@iut.verify_auth_message(@auth_message)).to eql(false)
    end

    it "should return false if the auth_message is not intended for the recipient" do
      env = @env
      env["HTTP_X_SMAAK_RECIPIENT"] = Base64.strict_encode64("another-recipient")
      auth_message = mock_auth_message(env)
      expect(@iut.verify_auth_message(auth_message)).to eql(false)
    end

    it "should return true if the auth_message is not intended for the recipient, but recipient verification is disabled" do
      env = @env
      env["HTTP_X_SMAAK_RECIPIENT"] = Base64.strict_encode64("another-recipient")
      auth_message = mock_auth_message(env)
      @iut.verify_recipient = false
      expect(@iut.verify_auth_message(auth_message)).to eql(true)
      @iut.verify_recipient = true
    end

    it "should return false if the auth_message's pre-shared key does not match the association's, indexed by the auth message's identifier field" do
      env = @env
      env["HTTP_X_SMAAK_PSK"] = "doesnotmatch"
      auth_message = mock_auth_message(env)
      expect(@iut.verify_auth_message(auth_message)).to eql(false)
    end

    it "should return true if the message successfully verifies" do
      expect(@iut.verify_auth_message(@auth_message)).to eql(true)
    end
  end

  context "when asked to verify a signed request" do
    it "should create an adaptor for the request" do
      expect(Smaak).to receive(:create_adaptor).with(@request)
      expect {
        @iut.verify_signed_request(@request)
      }.to raise_error
    end

    it "should build an auth message using the adaptor" do
      mock_adaptor = double(Smaak::RackAdaptor)
      expect(Smaak).to receive(:create_adaptor).with(@request).and_return(mock_adaptor)
      expect(@iut).to receive(:build_auth_message_from_request).with(mock_adaptor)
      expect {
        @iut.verify_signed_request(@request)
      }.to raise_error
    end

    it "should return false if the constructed auth message cannot be verified" do
      mock_adaptor = double(Smaak::RackAdaptor)
      expect(Smaak).to receive(:create_adaptor).with(@request).and_return(mock_adaptor)
      expect(@iut).to receive(:build_auth_message_from_request).with(mock_adaptor).and_return(@auth_message)
      expect(@iut).to receive(:verify_auth_message).and_return false
      expect(@iut.verify_signed_request(@request)).to eql(false)
    end

    it "should decrypt the request body if the auth_message indicates encryption" do
      mock_adaptor = double(Smaak::RackAdaptor)
      expect(Smaak).to receive(:create_adaptor).with(@request).and_return(mock_adaptor)
      expect(@iut).to receive(:build_auth_message_from_request).with(mock_adaptor).and_return(@auth_message)
      expect(@iut).to receive(:verify_auth_message).and_return true
      allow(@auth_message).to receive(:encrypt).and_return true
      expect(mock_adaptor).to receive(:body).and_return("body")
      expect(Smaak::Crypto).to receive(:sink).with("body").and_return("body")
      expect(Smaak::Crypto).to receive(:decrypt).with("body", @iut.private_key)
      expect {
        @iut.verify_signed_request(@request)
      }.to raise_error
    end

    it "should return false, nil if the headers could not be authorized" do
      mock_adaptor = double(Smaak::RackAdaptor)
      expect(Smaak).to receive(:create_adaptor).with(@request).and_return(mock_adaptor)
      expect(@iut).to receive(:build_auth_message_from_request).with(mock_adaptor).and_return(@auth_message)
      expect(@iut).to receive(:verify_auth_message).and_return true
      allow(@auth_message).to receive(:encrypt).and_return true
      expect(mock_adaptor).to receive(:body).and_return("body")
      expect(Smaak::Crypto).to receive(:sink).with("body").and_return("body")
      expect(Smaak::Crypto).to receive(:decrypt).with("body", @iut.private_key).and_return("body")
      expect(Smaak).to receive(:verify_authorization_headers).with(mock_adaptor, @test_server_public_key).and_return(false)
      auth_message, body = @iut.verify_signed_request(@request)
      expect(auth_message).to eql(false)
      expect(body).to eql(nil)
    end

    it "should return the auth_message and the body if successfully verified" do
      mock_adaptor = double(Smaak::RackAdaptor)
      expect(Smaak).to receive(:create_adaptor).with(@request).and_return(mock_adaptor)
      expect(@iut).to receive(:build_auth_message_from_request).with(mock_adaptor).and_return(@auth_message)
      expect(@iut).to receive(:verify_auth_message).and_return true
      allow(@auth_message).to receive(:encrypt).and_return true
      expect(mock_adaptor).to receive(:body).and_return("body")
      expect(Smaak::Crypto).to receive(:sink).with("body").and_return("body")
      expect(Smaak::Crypto).to receive(:decrypt).with("body", @iut.private_key).and_return("body")
      expect(Smaak).to receive(:verify_authorization_headers).with(mock_adaptor, @test_server_public_key).and_return(true)
      auth_message, body = @iut.verify_signed_request(@request)
      expect(auth_message).to eql(@auth_message)
      expect(body).to eql("body")
    end
  end


  context "when asked to compile a response" do
    it "should return the data provided if the auth_message provided does not indicate encryption" do
      expect(Smaak::Crypto).not_to receive(:encrypt)
      result = @iut.compile_response(@auth_message, "data")
      expect(result).to eql("data")
    end

    it "should return the data provided, encrypted with the public key of the associate identified by the auth_message if the auth_message provided indicates encryption" do
      allow(@auth_message).to receive(:encrypt).and_return true
      expect(Smaak::Crypto).to receive(:encrypt).with("data", @test_server_public_key).and_return("encrypted_data")
      result = @iut.compile_response(@auth_message, "data")
      expect(result).to eql("encrypted_data")
    end
  end
end
