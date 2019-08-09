require 'soar_idm/soar_idm'

module IdrStaff
  class HetznerStaffLdapTranslator
    def translate(entry)
      uuid, cn, object_classes, email = extract_fields(entry)
      build_entity(uuid, cn, object_classes, email)
    end

    private

    def build_entity(uuid, cn, object_classes, email)
      entity = {}
      entity['roles'] = extract_entity_roles(object_classes, cn, email)
      entity['uuid'] = uuid
      entity
    end

    def extract_entity_roles(object_classes, cn, email)
      roles = {}
      object_classes.each do |role|
        roles[role] = {}
        roles[role] = { 'name_and_surname' => cn,
                        'email_address' => email } if role == 'hetznerPerson'
      end
      roles
    end

    def extract_fields(entry)
      uuid = extract_uuid(entry)
      dn = entry.dn
      cn = entry['cn'].first
      object_classes = entry['objectClass']
      email = extract_email(dn)
      return uuid, cn, object_classes, email
    end

    def extract_uuid(entry)
      entry['entryUUID'].first if entry['entryUUID']
    end

    def extract_email(dn)
      email = nil
      dn.split(",").each do |value|
        email = value.split('=')[1] if value.include?('genie')
      end
      email
    end
  end
end
