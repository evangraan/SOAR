require 'jsender'
require 'soap4juddi'
#require 'byebug'

module SoarSr
  class Teams < SoarSr::DomainPerspectives
    include Jsender
    
      def team_registered?(domain_perspective)_{
        domain_registered?('teams', domain_perspective)
      }end

      def register_team(domain_perspective)_{
        register_domain('teams', domain_perspective)
      }end

      def deregister_team(domain_perspective)_{
        deregister_domain('teams', domain_perspective)
      }end   

      def list_teams
        @registry.domain_perspectives.list_domain_perspectives(['teams'])
      end   
  end
end
