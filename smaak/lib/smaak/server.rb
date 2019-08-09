require 'smaak'
require 'smaak/associate'
require 'smaak/auth_message'

module Smaak
  class Server < Associate
    attr_accessor :nonce_store
    attr_reader :private_key
    attr_accessor :verify_recipient

    def initialize
      super
      @nonce_store = Persistent::Cache.new("nonce_store", @token_life, Persistent::Cache::STORAGE_RAM)
      @verify_recipient = true
    end

    def set_public_key(key)
      set_key(key)
    end

    def set_private_key(key)
      @private_key = adapt_rsa_key(key)
    end

    def auth_message_unique?(auth_message)
      if nonce_store[auth_message.nonce].nil?
        nonce_store[auth_message.nonce] = 1
        return true
      end
      false
    end

    def build_auth_message_from_request(adaptor)
      puts "[smaak error]: x-smaak-* headers not all present. Is this a smaak request?" unless smaak_headers_all_present?(adaptor)
      recipient_public_key = Smaak::Crypto.decode64(adaptor.header("x-smaak-recipient"))
      psk = adaptor.header("x-smaak-psk")
      expires = adaptor.header("x-smaak-expires")
      identifier = adaptor.header("x-smaak-identifier")
      route_info = adaptor.header("x-smaak-route-info")
      nonce = adaptor.header("x-smaak-nonce")
      encrypt = adaptor.header("x-smaak-encrypt")
      Smaak::AuthMessage.build(recipient_public_key, psk, expires, identifier, route_info, nonce, encrypt)
    end

    def verify_auth_message(auth_message)
      return false unless verify_message_characteristics?(auth_message)
      identifier = auth_message.identifier
      verify_association_characteristics?(auth_message, identifier)
    end

    def verify_signed_request(request)
      adaptor = Smaak.create_adaptor(request)
      auth_message = build_auth_message_from_request(adaptor)
      unless verify_auth_message(auth_message)
        puts "[smaak error]: could not verify auth_message"
        return false
      end
      pubkey = @association_store[auth_message.identifier]['public_key']
      puts "[smaak warning]: pubkey not specified" if (pubkey.nil?) or (pubkey == "")
      body = Smaak::Crypto.sink(adaptor.body)
      body = Smaak::Crypto.decrypt(body, @private_key) if auth_message.encrypt
      unless Smaak.verify_authorization_headers(adaptor, pubkey)
        puts "[smaak error]: could not verify authorization headers"
        return false, nil
      end
      return auth_message, body # TBD return ID from cert
    end

    def compile_response(auth_message, data)
      return Smaak::Crypto.encrypt(data, @association_store[auth_message.identifier]['public_key']) if auth_message.encrypt
      data
    end

    private

    def verify_message_characteristics?(auth_message)
      verify_unique?(auth_message) and
      verify_public_key? and
      verify_intended_recipient?(auth_message)
    end

    def verify_association_characteristics?(auth_message, identifier)
      verify_associate?(identifier) and
      verify_expiry?(auth_message) and
      verify_psk?(auth_message, identifier)
    end

    def smaak_headers_all_present?(adaptor)
      not 
       (adaptor.header("x-smaak-recipient").nil? or
        adaptor.header("x-smaak-psk").nil? or
        adaptor.header("x-smaak-expires").nil? or
        adaptor.header("x-smaak-identifier").nil? or
        adaptor.header("x-smaak-nonce").nil? or
        adaptor.header("x-smaak-encrypt").nil?)
    end

    def verify_unique?(auth_message)
      unless auth_message_unique?(auth_message)
        puts "[smaak error]: message not unique"
        return false
      end
      true
    end

    def verify_public_key?
      if @key.nil? 
        puts "[smaak error]: public key not set. Did you call set_public_key() ?" 
        return false
      end
      true
    end

    def verify_intended_recipient?(auth_message)
      if (@verify_recipient) and (not auth_message.intended_for_recipient?(@key.export))
        puts "[smaak error]: message not intended for this recipient"
        return false
      #  verified = false
        # TBD - IOC this to smaak_bus
      #  if auth_message.router_info
      #    verified = auth_message.intended_for_recipient?(@association_store[auth_message.router_info])
      #  end
      #  unless verified
      #    puts "[smaak error]: message not intended for this recipient"
      #    return false
      #  end
      end
      true
    end

    def verify_associate?(identifier)
      if @association_store[identifier].nil?
        puts "[smaak error]: unknown associate #{identifier}"
        return false
      end
      true
    end

    def verify_expiry?(auth_message)
      if auth_message.expired?
        puts "[smaak error]: message expired. Are the sender and receiver's clocks in sync?"
        return false
      end
      true
    end

    def verify_psk?(auth_message, identifier)
      psk = @association_store[identifier]['psk']
      unless auth_message.verify(psk)
        puts "[smaak error]: PSK mismatch"
        return false
      end
      true
    end
  end
end
