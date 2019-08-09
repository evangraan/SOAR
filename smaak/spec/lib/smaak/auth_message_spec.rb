require './spec/spec_helper.rb'
require 'smaak'

describe Smaak::AuthMessage do
  before :all do
    @test_server_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_token_life = 10
    @test_nonce = 1234567890
    @test_psk = "testpresharedkey"
    @test_server_public_key = @test_server_private_key.public_key
    @test_identity = "test-service"
    @test_identifier = 'test-service-1.cpt1.host-h.net'
    @test_route_info = 'identifier'
    @test_recipient = @test_server_public_key.export
    @test_encrypt = true
  end

  before :each do
    @test_expires = Time.now.to_i + @test_token_life
    @iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, @test_encrypt)
  end

  context "when initialized" do
    it "should raise an ArgumentError if no identifier is provided" do
      expect {
        Smaak::AuthMessage.new(nil, @test_route_info, nil, nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid identifier set"
    end

    it "should raise an ArgumentError if no route information is provided" do
      expect {
        Smaak::AuthMessage.new(@test_identifier, nil, nil, nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid route information set"
    end

    it "should raise an ArgumentError if no nonce is provided" do
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, nil, nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid nonce set"
    end

    it "should raise an ArgumentError if an invalid nonce is provided" do
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, 0, nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid nonce set"
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, 'invalid nonce', nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid nonce set"
    end

    it "should raise an ArgumentError if no expiry is provided" do
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, nil, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid expiry set"
    end

    it "should raise an ArgumentError if an invalid expiry is provided" do
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, 0, nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid expiry set"
      expect {
        Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, 'invalid expire', nil, nil, nil)
      }.to raise_error ArgumentError, "Message must have a valid expiry set"
    end

    it "should remember the identifier provided" do
      expect(@iut.identifier).to eq(@test_identifier)
    end

    it "should remember the nonce provided" do
      expect(@iut.nonce).to eq(@test_nonce)
    end

    it "should remember the expiry provided" do
      expect(@iut.expires).to eq(@test_expires)
    end

    it "should remember the psk provided" do
      expect(@iut.psk).to eq(Smaak::Crypto.obfuscate_psk(@test_psk))
    end

    it "should remember the recipient provided" do
      expect(@iut.recipient).to eq(@test_recipient)
    end

    it "should remember a boolean representation of whether encryption is required" do
      expect(@iut.encrypt).to eq(true)
    end

    it "should translate the encrypt parameter from string to boolean" do
      iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, false)
      expect(iut.encrypt).to eq(false)
      
      iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, true)
      expect(iut.encrypt).to eq(true)
      
      iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, "false")
      expect(iut.encrypt).to eq(false)
      
      iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, "true")
      expect(iut.encrypt).to eq(true)
    end
  end

  context "when asked if it has expired" do
    it "should return true if the current timestamp exceeds that of the message expiry" do
      iut = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, Time.now - 1, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, false)
      expect(iut.expired?).to eq(true)
    end

    it "should return false if the current timestamp does not exceed that of the message expiry" do
      expect(@iut.expired?).to eq(false)
    end
  end

  context "when asked whether a message's psk matched" do
    it "should return false if the PSKs do not match" do
      expect(@iut.psk_match?("doesnotmatch")).to eq(false)
    end

    it "should return true if the PSKs do match" do
      expect(@iut.psk_match?(@test_psk)).to eq(true)
    end
  end

  context "when asked whether this message is intended for a recipient, identified by public key" do
    it "should return false if the recipient does not match the public key specified" do
      mismatched = OpenSSL::PKey::RSA.new(4096).public_key
      expect(@iut.intended_for_recipient?(mismatched.export)).to eq (false)
    end

    it "should return false if the public key is not specified" do
      expect(@iut.intended_for_recipient?(nil)).to eq (false)
    end

    it "should return true if the recipient matches the public key specified" do
      expect(@iut.intended_for_recipient?(@test_server_public_key.export)).to eq (true)
    end
  end

  context "when asked to verify the message" do
    it "should try and match the PSK and return false if it cannot" do
      expect(@iut).to(receive(:psk_match?)).and_return(false)
      expect(@iut.verify(Smaak::Crypto.obfuscate_psk(@test_psk))).to eq(false)
    end

    it "should return true if the message was successfully verified" do
      expect(@iut.verify(@test_psk)).to eq(true)
    end
  end

  context "when asked to create an AuthMessage from scratch" do
    it "should initialize with the recipient_public_key, psk, expires, identifier, nonce, encrypt provided, calculating expiry, generating a nonce, and obfuscating the PSK" do
      allow(Smaak::Crypto).to receive(:generate_nonce).and_return(@test_nonce)
      expect(Smaak::AuthMessage).to receive(:new).with(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, @test_encrypt)
      Smaak::AuthMessage.create(@test_recipient, @test_psk, @test_token_life, @test_identifier, @test_route_info, @test_encrypt)
    end
  end

  context "when asked to build an AuthMessage from existing data" do
    it "should initialize with the recipient_public_key, psk, expires, identifier, nonce, encrypt provided" do
      expect(Smaak::AuthMessage).to receive(:new).with(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, @test_encrypt)
      Smaak::AuthMessage.build(@test_recipient, Smaak::Crypto.obfuscate_psk(@test_psk), @test_expires, @test_identifier, @test_route_info, @test_nonce, @test_encrypt)
    end
  end
end
