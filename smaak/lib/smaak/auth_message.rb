require 'smaak/crypto'

module Smaak
  class AuthMessage
    attr_reader :identifier
    attr_reader :route_info
    attr_reader :nonce
    attr_reader :recipient
    attr_reader :psk
    attr_reader :expires
    attr_reader :encrypt

    def self.create(recipient_public_key, psk, token_life, identifier, route_info = "", encrypt = false)
      nonce = Smaak::Crypto.generate_nonce
      expires = Time.now.to_i + token_life
      # Must obfuscate PSK. AuthMessage must always have an obfuscated PSK
      psk = Smaak::Crypto.obfuscate_psk(psk)
      AuthMessage.build(recipient_public_key, psk, expires, identifier, route_info, nonce, encrypt)
    end

    def self.build(recipient_public_key, psk, expires, identifier, route_info, nonce, encrypt = false)
      # No need to obfuscate PSK. Off the wire we should always expect an obfuscated PSK
      AuthMessage.new(identifier, route_info, nonce, expires, psk, recipient_public_key, encrypt)
    end

    def initialize(identifier, route_info, nonce, expires, psk, recipient_public_key, encrypt)
      set_and_validate_identifier(identifier)
      set_and_validate_route_info(route_info)
      set_and_validate_nonce(nonce)
      set_and_validate_expires(expires)
      set_recipient(recipient_public_key)
      set_psk(psk)
      set_encrypt(encrypt)
    end

    def set_and_validate_identifier(identifier)
      raise ArgumentError.new("Message must have a valid identifier set") if identifier.nil? or identifier.empty?      
      @identifier = identifier
      @identifier.freeze
    end

    def set_and_validate_route_info(route_info)
      raise ArgumentError.new("Message must have a valid route information set") if route_info.nil?
      @route_info = route_info
      @route_info.freeze
    end

    def set_and_validate_nonce(nonce)
      raise ArgumentError.new("Message must have a valid nonce set") unless validate_nonce(nonce)
      @nonce = nonce
      @nonce.freeze
    end

    def set_and_validate_expires(expires)
      raise ArgumentError.new("Message must have a valid expiry set") unless validate_expiry(expires)
      @expires = expires
    end

    def set_recipient(recipient_public_key)
      @recipient = recipient_public_key
    end

    def set_psk(psk)
      @psk = psk
    end

    def set_encrypt(encrypt)
      @encrypt = false
      @encrypt = true if encrypt == "true" or encrypt == true
    end

    def expired?
      @expires.to_i < Time.now.to_i
    end

    def psk_match?(psk)
      return false if psk.nil?
      return false if @psk.nil?
      @psk == Smaak::Crypto.obfuscate_psk(psk)
    end

    def intended_for_recipient?(pubkey)
      return false if pubkey.nil?
      return false if @recipient.nil?
      @recipient == pubkey
    end

    def verify(psk)
      return false unless psk_match?(psk)
      true
    end

    private

    def validate_nonce(nonce)
      return false if nonce.nil?
      return false if nonce.to_i == 0
      true

      rescue
        false
    end

    def validate_expiry(expires)
      return false if expires.nil?
      return false unless (expires.to_i > 0)
      true

      rescue
        false
    end
  end
end
