require 'soar_ldap'

module IdrStaff
  class HetznerStaffLdap < SoarLdap::LdapProvider
    def find_entity(connection, identifier)
      connection.search(@path, ::LDAP::LDAP_SCOPE_SUBTREE, 'objectClass=*', ['objectClass', 'cn', 'dn', 'entryuuid', 'description']) do |entry|
        uuid = entry['entryUUID'].first
        dn = entry.dn
        return entry if uuid == identifier
        return entry if dn and dn == "genieUser=#{identifier.downcase},ou=people,dc=hetzner,dc=co,dc=za"
      end
      nil
    end
  end
end
