require './spec/spec_helper.rb'
require 'smaak'

describe Smaak::Associate do
  before :all do
    @test_private_key = OpenSSL::PKey::RSA.new(4096)
    @test_psk = "testpresharedkey"
    @test_public_key = @test_private_key.public_key
  end

  before :each do
    @iut = Smaak::Associate.new
  end

  context "when initialized" do
    it "should have an association store" do
      expect(@iut.association_store.class).to eq(Persistent::Cache)
    end
    it "should default to DEFAULT_TOKEN_LIFE if a token life is not provided" do
      expect(@iut.token_life).to eq(Smaak::DEFAULT_TOKEN_LIFE)
    end
  end

  context "when given its own key" do
    it "should remember its own key" do
      @iut.set_key(@test_public_key)
      expect(@iut.key).to eq(@test_public_key)
    end

    it "should convert its own key from string to RSA if given a string" do
      @iut.set_key(@test_public_key.export)
      expect(@iut.key.export).to eq(@test_public_key.export)
    end

    it "should raise an ArgumentError if the key is not a valid key" do
      error = "Key needs to be valid"
      expect {
        @iut.set_key(nil)
      }.to raise_error ArgumentError, error
      expect {
        @iut.set_key(1)
      }.to raise_error ArgumentError, error
      expect {
        @iut.set_key("")
      }.to raise_error ArgumentError, error
    end
  end

  context "when given a token life" do
    it "should remember a token life provided" do
      @iut.set_token_life(6)
      expect(@iut.token_life).to eq(6)
    end

    it "should raise an ArgumentError if the token life provided is not a valid number > 0" do
      error = "Token life has to be a positive number of seconds"
      expect {
        @iut.set_token_life(nil)
      }.to raise_error ArgumentError, error
      expect {
        @iut.set_token_life(0)
      }.to raise_error ArgumentError, error
      expect {
        @iut.set_token_life(-1)
      }.to raise_error ArgumentError, error
      expect {
        @iut.set_token_life("1")
      }.to raise_error ArgumentError, error
    end
  end

  context "when told about an association" do
    error = "Key needs to be valid"
    it "should raise an ArgumentError if the association does not have a valid key" do
      expect {
        @iut.add_association("test", nil, "psk")
      }.to raise_error ArgumentError, error
      expect {
        @iut.add_association("test", 1, "psk")
      }.to raise_error ArgumentError, error
      expect {
        @iut.add_association("test", "", "psk")
      }.to raise_error ArgumentError, error
    end

    it "should remember the association's name, public key and pre-shared key" do
      @iut.add_association("test", @test_public_key, @test_psk)
      expect(@iut.association_store["test"].nil?).to eq(false)
      expect(@iut.association_store["test"]["public_key"]).to eq(@test_public_key)
      expect(@iut.association_store["test"]["psk"]).to eq(@test_psk)
    end

    it "should convert string keys into RSA keys" do
      @iut.add_association("test", @test_public_key.export, @test_psk)
      expect(@iut.association_store["test"]["public_key"].export).to eq(@test_public_key.export)
    end
  end
end
