# Idr Client

## Documentation
[Ruby Gems](https://rubygems.org/gems/idr_client)

## Example use

Get roles for subject identifier
```ruby
idr_client = SoarSc::IdrClient.new
idr_client.roles_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-roles')
subject_identifier = 'charles.mulder@example.org'
roles = idr_client.get_roles(subject_identifier)
```

Get attributes for specific role of subject identifier
```ruby
idr_client = SoarSc::IdrClient.new
idr_client.roles_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-roles')
idr_client.attributes_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-attributes')
subject_identifier = 'charles.mulder@example.org'
role = 'technical'
attributes = idr_client.get_attributes(subject_identifier, role)
```

Get all attributes for subject identifier
```
idr_client = SoarSc::IdrClient.new
idr_client.attributes_uri = SoarSc::Providers::ServiceRegistry::find_first_service_uri('idr-staff-get-attributes')
subject_identifier = 'charles.mulder@example.org'
attributes = idr_client.get_attributes(subject_identifier)
```

## Test

Run unit tests with
```bash
$ rspec
```
