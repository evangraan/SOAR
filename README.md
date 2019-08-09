# SOAR

SOAR is a ruby micro-services architecture built from a comprehensive set of SOA components.
When used together, they facilitate rapid ruby & rack based microservices implementations.

## Components:
eh: Error handler gem that allows wrapping of code blocks with support for block retry, logging, exception filtering and re-raise
idr_client: Identity registry for staff entries in LDAP
idr_staff: Model for staff IDR
jsender: JSender facilitates a simple jsend implementation for ruby
persistent-cache: Persistent Cache using a pluggable back-end
persistent-cache-ram: RAM storage for persistent-cache
persistent-cache-storage-api: This gem encodes the API that Persistent::Cache providers adhere to in order to plug in as a back-end provider.
persistent-cache-storage-directory: provides a directory storage back-end to Persistent::Cache.
shexecutor: Execute shell commands easily and securely
smaak: This gems caters for both client and server side of a signed message interaction over HTTP or HTTPS implementing the RFC2617 Digest Access Authentication. The following compromises are protected against as specified: Man in the middle / snooping (HTTPS turned on), Replay (nonce + expires), Forgery (signature), Masquerading (recipient pub key check), Clear-text password compromise (MD5 pre-shared key)
soap4juddi: Provides connector, xml and brokerage facilities to a jUDDI consumer
soar_am: Access Manager API for the SOAR architecture
soar_aspects: Library facilitating seeding of SOAR aspects in the rack environment
soar_auditing_provider: SOAR architecture auditing provider
soar_auditor_api: SOAR auditor api
soar_authentication: Authentication middleware for SOAR
soar_authentication_cas: CAS configuration for soar_sc
soar_authorization: Matches resource requests with access managers and asks them to authorize
soar_configuration: Configuration library for loading configuration service and YAML configurations
soar_environment: This library determines the set of environment variables for a service component in the SOAR architecture
soar_idm: Generic implementation of a SOAR Identity management API
soar_ldap: LDAP client library allowing easy acces to entries on LDAP servers
soar_lexicon: Provides a dynamic service component WADL lexicon and individal service ?wadl lexicon
soar_pl: Generic implementation of a SOAR authorization policy
soar_policy_access_manager: Access Manager that uses policy services to determine authorization
soar_sc_core: Service component core aggregations
soar_sc_mvc: MVC library for SOAR reference implementation service component
soar_sc_routing: base router and router meta library for soar_sc
soar_sc_views: collection of soar_sc views
soar_smaak: Rack middle-ware for supporting SMAAK communication
soar_sr: Implementation of the Hetzner Service Registry specification, backed by jUDDI
soar_transport_api: API to be implemented by transport providers that want to communicate across soar_comms communication fabric
soar_wadl_validation: WADL validator for requests
soar_xt: Library extension for the SOAR architecture
wadling: Given a dictionary of resources with a description, input and output schemas, produces a WADL definition

