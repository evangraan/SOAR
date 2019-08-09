module SoarSr
	class Contacts < SoarSr::Handler
      def add_contact_to_domain_perspective(domain_perspective, contact)_{
        domain_perspective = standardize(domain_perspective)            
        authorize
        provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
        provided?(contact, 'contact details') and contact?(contact)
        details = {}.merge!(contact)
        details = ensure_required_contact_details(details)

        result = @registry.domain_perspectives.domain_perspective_registered?(domain_perspective)
        result =  @registry.teams.team_registered?(domain_perspective) if result['data']['id'].nil?

        id = result['data']['id']
        domain_perspective = @uddi.get_business(id)['data'].first[1]

        domain_perspective['contacts'] ||= []

        return fail('contact already exists - remove first to update') if contacts_include?(domain_perspective['contacts'], details)

        domain_perspective['contacts'] << details

        @uddi.save_business(id, domain_perspective['name'], domain_perspective['description'], domain_perspective['contacts'])
      }end

      def contact_details_for_domain_perspective(domain_perspective)_{
        domain_perspective = standardize(domain_perspective)            
        provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
        result = @registry.domain_perspectives.domain_perspective_registered?(domain_perspective)
        result =  @registry.teams.team_registered?(domain_perspective) if result['data']['id'].nil?
        id = result['data']['id']
        domain_perspective = @uddi.get_business(id)['data'].first[1]
        domain_perspective['contacts'] ||= []
        domain_perspective['contacts'].each do |contact|
          contact['description'] = '' if contact['description'] == 'n/a'
          contact['email'] = '' if contact['email'] == 'n/a'
          contact['phone'] = '' if contact['phone'] == 'n/a'
        end
        success_data('contacts' => domain_perspective['contacts'])
      }end

      def remove_contact_from_domain_perspective(domain_perspective, contact)_{
        domain_perspective = standardize(domain_perspective)            
        authorize
        provided?(domain_perspective, 'domain perspective') and any_registered?(domain_perspective)
        provided?(contact, 'contact details') and contact?(contact)

        result = @registry.domain_perspectives.domain_perspective_registered?(domain_perspective)
        result =  @registry.teams.team_registered?(domain_perspective) if result['data']['id'].nil?

        id = result['data']['id']
        domain_perspective = @uddi.get_business(id)['data'].first[1]

        domain_perspective['contacts'] ||= []

        return fail('unknown contact') if not contacts_include?(domain_perspective['contacts'], contact)

        domain_perspective['contacts'].delete(contact)
        domain_perspective['contacts'] = nil if domain_perspective['contacts'] == []

        @uddi.save_business(id, domain_perspective['name'], domain_perspective['description'], domain_perspective['contacts'])
      }end
      
      private

      def ensure_required_contact_details(details)
        details['description'] = 'n/a' if details['description'].nil? or details['description'].strip == ""
        details['email'] = 'n/a' if details['email'].nil? or details['email'].strip == ""
        details['phone'] = 'n/a' if details['phone'].nil? or details['phone'].strip == ""
        details
      end

      def contacts_include?(contacts, contact)
        contacts.each do |compare|
          return true if (compare['name'] == contact['name']) and (compare['email'] == contact['email']) and (compare['description'] == contact['description']) and (compare['phone'] == contact['phone'])
        end
        false
      end
	end
end
