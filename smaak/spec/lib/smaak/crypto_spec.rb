require './spec/spec_helper.rb'

describe Smaak::Crypto do
  before :all do
    @private_key = OpenSSL::PKey::RSA.new(4096)
    @data = {'a' => 'B'}.to_json
    @bdata = Base64.strict_encode64(@data)
    @digest = OpenSSL::Digest::SHA256.new
    @signature = @private_key.sign(@digest, @bdata)
    @public_key = @private_key.public_key
  end

  context "when asked to obfuscate a clear-text psk" do
    it "should reverse the psk and apply an MD5 hexadecimal digest to the result" do
      expect(Smaak::Crypto.obfuscate_psk('sharedsecret')).to eq(Digest::MD5.hexdigest('sharedsecret'.reverse))
    end
  end

  context "when asked to generate a nonce" do
    it "should generate a random nonce with at most 1 in a ten billion probability of a consecutive clash" do
      expect(SecureRandom).to receive(:random_number).with(10000000000)
      Smaak::Crypto.generate_nonce
    end

    it "should generate a different nonce every time with high probability (less than 1 in 10000) given a history of 1000000 nonces" do
      repeat = {}
      failed = 0
      threshold = 1000000
      threshold.times do
        value = Smaak::Crypto.generate_nonce
        failed = failed + 1 if repeat[value] == 1
        repeat[value] = 1
      end
      failed_p = (failed.to_f / threshold) * 100
      puts "I've seen #{failed_p} % of nonces before in #{threshold} generations"
      expect(failed_p < 0.01).to eq(true)
    end
  end

  context "when asked to encode data using base 64" do
    it "should encode the data without newlines or line feeds using base 64 (strict)" do
      data = "some data"
      expect(Smaak::Crypto.encode64(data)).to eq(Base64.strict_encode64(data))
    end
  end

  context "when asked to decode data using base 64" do
    it "should decode the data using base 64 (strict)" do
      expect(Smaak::Crypto.decode64(Base64.strict_encode64("some data"))).to eq("some data")
    end
  end

  context "when asked to sign data given a private key" do
    it "should sign a strict Base64 representation of the data with the key using a 256 bit SHA digest" do
      expect(Smaak::Crypto.sign_data(@data, @private_key)).to eq(@signature)
    end
  end

  context "when asked to verify a signature given data and a public key" do
    it "should verify using a 256 bit SHA digest" do
      expect(OpenSSL::Digest::SHA256).to receive(:new).and_return(@digest)
      Smaak::Crypto.verify_signature(@signature, @bdata, @public_key)
    end 

    it "should return true when the signature is verified by the public key" do
      expect(Smaak::Crypto.verify_signature(@signature, @bdata, @public_key)).to eq(true)
    end

    it "should return false when the signature cannot be verified by the public key" do
      other_key = OpenSSL::PKey::RSA.new(4096).public_key
      expect(Smaak::Crypto.verify_signature(@signature, @bdata, other_key)).to eq(false)
    end
  end

  context "when asked to encrypt data given a public key" do
    it "should return a base64 representation of the data encrypted with the public key" do
      expect(@private_key.private_decrypt(Base64.strict_decode64(Smaak::Crypto.encrypt(@data, @public_key)))).to eq(@data)
    end
  end

  context "when asked to decrypt encrypted data given a private key" do
    it "should return a decryption using the private key of a base64 decode of the data" do
      expect(Smaak::Crypto.decrypt(Base64.strict_encode64(@public_key.public_encrypt(@data)), @private_key)).to eq(@data)
    end
  end

  context "when asked to sync data from an IO stream" do
    it "should sink all data from the stream, collating when nil is read" do
      mock_stream = double(Object)
      allow(mock_stream).to receive(:gets).and_return("a", "b", nil)
      expect(Smaak::Crypto.sink(mock_stream)).to eq("ab")
    end
  end
end
