require 'base64'

module Smaak
  class Crypto
    def self.obfuscate_psk(psk)
      Digest::MD5.hexdigest(psk.reverse)
    end

    def self.generate_nonce
      SecureRandom.random_number(10000000000)
    end

    def self.encode64(data)
      Base64.strict_encode64(data)
    end

    def self.decode64(data)
      Base64.strict_decode64(data)
    end

    def self.sign_data(data, private_key)
      digest = OpenSSL::Digest::SHA256.new
      private_key.sign(digest, Smaak::Crypto.encode64(data))
    end

    def self.verify_signature(signature, data, public_key)
      digest = OpenSSL::Digest::SHA256.new
      public_key.verify(digest, signature, data)
    end

    def self.encrypt(data, public_key)
      Base64.strict_encode64(public_key.public_encrypt(data))
    end

    def self.decrypt(data, private_key)
      private_key.private_decrypt(Base64.strict_decode64(data))
    end

    def self.sink(stream)
     data = ""
     while t = stream.gets do
       data = data + t
     end
     data
    end
  end
end
