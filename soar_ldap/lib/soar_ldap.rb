require "soar_ldap/version"
require 'ldap'
require 'ldap/control'
require 'soar_idm/directory_provider'
require 'persistent-cache'

module SoarLdap
  class SoarLdapError < StandardError
  end

  class LdapProvider < SoarIdm::DirectoryProvider
    attr_reader :configuration
    attr_reader :path
    attr_reader :server
    attr_reader :port
    attr_reader :credentials
    attr_reader :username
    attr_reader :password    
    attr_reader :connection
    attr_reader :cache

    def initialize(configuration)      
      bootstrap(configuration)
    end

    def bootstrap(configuration)
      @configuration = nil
      validate_configuration(configuration)
      remember_configuration(configuration)
      initialize_cache(configuration)
    end

    def bootstrapped?
      not @configuration.nil?
    end

    def authenticate(credentials)
      @credentials = nil
      validate_credentials(credentials)
      remember_credentials(credentials)
    end

    def connect
      @connection = ::LDAP::Conn.new(@server, @port)
      @connection.set_option(::LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @connection.bind(@username, @password)
      @connection

    rescue => ex
      raise SoarLdapError.new("Connection error + #{ex}")
    end

    def connected?
      not @connection.nil?
    end

    def ready?
      bootstrapped? and connected?
    end

    def uri
      raise SoarLdapError.new('Not bootstrapped') if not bootstrapped?
      "ldap://#{server}:#{port}/#{@path}"
    end

    def get_entity(identifier)
      connect if not connected?
      cached = retrieve_from_cache(@connection, identifier)
      return cached if cached
      result = find_entity(@connection, identifier)
      cache_result(@connection, identifier, result)
      result

    rescue => ex
      raise SoarLdapError.new("Lookup error, #{ex}")
    end

    protected

    def find_entity(connection, identifier)
      connection.search(@path, ::LDAP::LDAP_SCOPE_SUBTREE, 'objectClass=*', ['objectClass', 'cn', 'dn', 'entryuuid', 'description']) do |entry|
        uuid = entry['entryUUID'].first
        dn = entry.dn
        return entry if uuid == identifier
        return entry if dn and dn.include?(identifier)
      end
      nil
    end

    private

    def validate_configuration(configuration)
      raise SoarLdapError.new('No configuration') if configuration.nil?
      raise SoarLdapError.new('Empty configuration') if configuration == {}
      raise SoarLdapError.new('Invalid configuration') if not configuration.is_a?(Hash)
      raise SoarLdapError.new('Missing server') if configuration['server'].nil?
      raise SoarLdapError.new('Missing port') if configuration['port'].nil?
      raise SoarLdapError.new('Missing path') if configuration['path'].nil?
    end

    def validate_credentials(credentials)
      raise SoarLdapError.new('Missing credentials') if credentials.nil?
      raise SoarLdapError.new('Empty credentials') if credentials == {}
      raise SoarLdapError.new('Invalid credentials') if not credentials.is_a?(Hash)
      raise SoarLdapError.new('Missing username') if credentials['username'].nil?
      raise SoarLdapError.new('Missing password') if credentials['password'].nil?
    end

    def remember_configuration(configuration)
      @configuration = configuration
      @server = @configuration['server']
      @port = @configuration['port'].to_i
      @path = @configuration['path']
    end

    def remember_credentials(credentials)
      @credentials = credentials
      @username = @credentials['username']
      @password = @credentials['password']
    end

    def retrieve_from_cache(connection, identifier)
      cached_connection = @cache[connection.to_s]
      if cached_connection
        cached_value = @cache[connection.to_s][identifier]
        return cached_value if cached_value
      end
      nil
    end

    def cache_result(connection, identifier, result)
      return if @freshness == 0
      @cache[connection.to_s] ||= {}
      @cache[connection.to_s][identifier] = result
    end

    def initialize_cache(configuration)
      @freshness = configuration['freshness']
      @freshness ||= 0
      @cache = ::Persistent::Cache.new("soar_ldap", @freshness, Persistent::Cache::STORAGE_RAM)
    end
  end
end
