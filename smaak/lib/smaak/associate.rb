require 'persistent-cache'

module Smaak
  class Associate
    attr_reader :association_store
    attr_reader :token_life
    attr_reader :key

    def initialize
      @association_store = Persistent::Cache.new("association_store", nil, Persistent::Cache::STORAGE_RAM)
      @token_life = Smaak::DEFAULT_TOKEN_LIFE
    end

    def set_key(key)
      @key = adapt_rsa_key(key)

      rescue OpenSSL::PKey::RSAError
        raise ArgumentError.new("Key needs to be valid")
    end

    def set_token_life(token_life)
      raise ArgumentError.new("Token life has to be a positive number of seconds") unless validate_token_life(token_life)
      @token_life = token_life
    end

    def add_association(identifier, key, psk, encrypt = false)
      the_key = key.is_a?(String) ? OpenSSL::PKey::RSA.new(key) : key
      raise ArgumentError.new("Key needs to be valid") unless validate_key(the_key)
      @association_store[identifier] = { 'public_key' => the_key, 'psk' => psk, 'encrypt' => encrypt }

      rescue OpenSSL::PKey::RSAError
        raise ArgumentError.new("Key needs to be valid")
    end

    protected

    def adapt_rsa_key(key)
      the_key = key.is_a?(String) ? OpenSSL::PKey::RSA.new(key) : key
      raise ArgumentError.new("Key needs to be valid") unless validate_key(the_key)
      the_key
    end

    private

    def validate_key(key)
      return false if key.nil?
      return false if key.is_a? String and key.empty?
      return false unless key.is_a? OpenSSL::PKey::RSA
      true
    end

    def validate_token_life(token_life)
      return false if token_life.nil?
      return false unless token_life.is_a? Integer
      return false unless token_life > 0
      true
    end
  end
end
