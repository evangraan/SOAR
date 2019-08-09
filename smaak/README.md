# Smaak

[![Gem Version](https://badge.fury.io/rb/smaak.png)](https://badge.fury.io/rb/smaak)
[![Build Status](https://travis-ci.org/evangraan/smaak.svg?branch=master)](https://travis-ci.org/evangraan/smaak)
[![Coverage Status](https://coveralls.io/repos/github/evangraan/smaak/badge.svg?branch=master)](https://coveralls.io/github/evangraan/smaak?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/e7a22dd7299242fcae3f3dda681103f6)](https://www.codacy.com/app/ernst-van-graan/smaak?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=evangraan/smaak&amp;utm_campaign=Badge_Grade)

This gems caters for both client and server sides of a signed message interaction over HTTP implementing RFC2617 Digest Access Authentication as well as IETF draft-cavage-http-signatures-04, extended with 'x-smaak-recipient', 'x-smaak-identifier', 'x-smaak-route-info', 'x-smaak-psk', 'x-smaak-expires' and 'x-smaak-nonce' headers. The following compromises are protected against as specified: Man in the middle (header and payload signature, as well as body digest) / snooping (message body encryption), Replay (nonce + expiry), Forgery (signature), Masquerading (identifier and signature), Forwarding / Unintended recipient (recipient pub key check), Clear-text password compromise (MD5 pre-shared key, obfuscated), lack of password (pre-shared key), Message fabrication (associations are purpose-fully provisioned to known associates.)

## Smaak mechanism

When provisioning a Smaak::Server and a Smaak::Client, all associations these services should be aware of are provisioned by calling add_association. The associations are indexed by identifier (e.g. FQDN of the associate,) and remember the associate's public key, a pre-shared key and a boolean indicating whether the association expects data to be encrypted.

Smaak appends 'x-smaak' headers to the HTTP request to convey a generated nonce, expiry, the requestor's identifier, the pre-shared key (obfuscated) and a digest of the request body. The headers are signed using the requestor (Smaak::Client)'s private key. If encryption is requested, the message body is encrypted using the receiver (Smaak::Server)'s public key. The message body for the response from the Smaak::Server to the Smaak::Client is also encrypted. RSA 4096 bit keys are recommended.

The signing of an HTTP request and the placement of the signature in an Authorization header is performed by a signing specification specified when signing. The algorithm implementing the signing specification is expected to embed a Smaak::AuthMessage in the signature and allow access to it when the signed header is interpreted. Currently IETF draft-cavage-http-signatures-04 is the only supported signature specification.

Smaak verifies an AuthMessage signed in the Authorization header by looking at nonce, expiry, recipient and pre-shared key. The order of headers signed is important for signature verification.

### Requires

In order for smaak to utilize adaptors and technology you choose, ensure to require the necessary libraries. For example:

    require 'rack'
    require 'net'
    require 'net/http'

### Example Server

A Smaak::Server operates on an instance of an HTTP request received. The Smaak module can be told about different request technology implementations by providing an adaptor to a request technology (Smaak.add_request_adaptor). The gem ships with a Rack::Request adaptor. Call Smaak.create_adaptor with your request to get an instance of an adaptor.

A Smaak::Server needs to keep track of nonces received in the fresh-ness interval of requests. To make this easy, you can extend Smaak::SmaakService. Override the configure_services method to provide your server's public key, private key and associations. Smaak::SmaakService provides a cache of received nonces checked against the freshness interval.

When setting up a Smaak::Server, tell the server of your SmaakService and verify incoming request, so:

    class SecureServer < Smaak::SmaakService
      def configure_services(configuration = nil)
        @smaak_server.set_public_key(File.read '/secure/server_public.pem')
        @smaak_server.set_private_key(File.read '/secure/server_private.pem') # only required when encryption is specified
        @smaak_server.add_association('client-facing-service-needing-back-end-data', File.read '/secure/client_public.pem', 'client-pre-shared-key')
      end
    end

    class SecureService
      def serve(request)
        auth_message, body = SecureServer.get_instance.smaak_server.verify_signed_request(request)
        return [200, "message from #{auth_message.identifier} verified!"] if auth_message.identifier
        [401, "Insufficient proof!"]
      end
    end

Note: verification of intended recipient can be disabled, e.g. in cases of dynamic
trust stores as follows. USE WITH CAUTION:

    server.verify_recipient = false

### Example Client

A Smaak::Client operates on an instance of an HTTP request. The Smaak module can be told about different request technology implementations by providing an adaptor to a request technology (Smaak.add_request_adaptor). The gem ships with a Net::HTTP adaptor. Call Smaak.create_adaptor with your request to get an instance of an adaptor.

    # The user requested some data which requires my service to talk to another, a Smaak::Server
    class SecureController
      def initialize
        # We recommend this configuration be provisioned by a secure configuration service and/or by service boot-strapping
        @client = Smaak::Client.new
        @client.set_identifier('client-facing-service-needing-back-end-data')
        @client.set_private_key(File.read '/secure/client_private.pem')
        @client.add_association('service-provider', File.read('/secure/server_public.pem'), 'client-pre-shared-key', true) # encrypted
      end

      def serve(request)
        response = @client.post('service-provider', 'http://service-provider.com:9393/backend', { 'index1' => 'data1', 'index2' => 'data2' }.to_json)
        [200, response.body]
      end
    end

    class SecureConsumer
      def initialize
        ...
      end

      def some_other(param)
        response = @client.get('service-provider', 'http://service-provider.com:9393/query', { 'looking_for' => param }.to_json)
        consume_response(response)
      end
    end

## Identity management

During provisioning, we recommend that the key-pair that does the signing and verification has associated with it an X.509 certificate signed by a CA you trust that contains the identity of the signer. The association is provisioned with an 'identifier' that the Authorization header transports in the 'x-smaak-identifier' header. This identifier is used on the receiver end to look up the public key of the signer in the association list. Once the associated key successfully verifies the signature, that certificate's identity can be used for identity management and authorization. This allows multiple identifiers (e.g. multiple server heads) to represent a single service (identity) with separate signing certs for each head.

As an additional optional identifying header, x-smaak-rout-info can be utilized (e.g. in cases where x-smaak-identifier is a bus identifier and there is a need to also identify the entity that engaged on the bus)

## Example on-the-wire requests

### Un-encrypted

    POST http://service-provider-internal:9393/secure-service HTTP/1.1
    Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3
    Accept: */*
    User-Agent: Ruby
    Authorization: Signature keyId="rsa-key-1",algorithm="rsa-sha256", headers="host date digest x-smaak-recipient x-smaak-identifier x-smaak-psk x-smaak-expires x-smaak-nonce x-smaak-encrypt content-length", signature="DywQfsuJOzP7uQw/rZ3sEKtyBlzs+3Gqif/WEjjxjC1h6/vsMP6LHz1jeCQdBWRgPZ/NonM06NeSWei/YXpg9dtntoWWHQ8e8pvQsLVrx0BuMAyGhckuE9IcUSnaAOqCGCTcEV2cIE6a50tPSbBHS88jzIasliMrM8QIG2boIB9hMXbYNCPUzUKo7mOtda2NUrGwYflmLZ1cXuRGHeXuG/m/kYJOSSUawrneWH3uxuIhJTQiVtblYr7tHDQsAB6WJgCxLkrZJreALYyM62D6Cpvip3atMoKh+2b3/SqseSdt2BirrMiTdS+1+6Tyk+z/y9sGhEF0WZoIOZUmo1+7yfXe4hHaa7SQD8olsjoJTPaBsd39sb5xPZKsFS3k/eeWQxXEa7iLLumDgHncaIhyRkyb+XTG6/qk0XemBuc4LlU1JjFCdGYjYx0T9V9OUrt8Jpi6g2FKg8JLaJsd2Xk4sUBwHMrYwweutdCXxbHZn2VYF5BydDB+Eesc62PC8jh1xiAVperSUF60HdOLhcJp/eJz7VuyjaRx+EYVNqBHxIG9w9si/pcxy6tX2yA5Go+UJ37xG5E12P3QNDC6HBEEqq8tOW+YqnOacm+IbI2YSZ/ilEbSYhmE/KH7GZKxl1cSvswHcDrYRwFhviSPutQGBtGl6o/YjdmpYAVcZiEGUtE="
    Host: service-provider-internal
    Date: 2015-06-25 09:48:13 GMT
    Digest: SHA-256=0190f465c943501984c4018bacdbb0be167979f261caf1fe50ce63e97d31dff2
    X-Smaak-Recipient: LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxL2tiYjdBNWllQWV1WlBBVnI3MAo5cjl1TkFzc2dmYkdjeGMzZTc3RDNndkY4U2tzbURNQmQyTUt5TUh0ZjBrM1pqSVdZemJJVG5jQXM1Nnd4cmRSClhiVHpIZnhjMll1dDMwd0ljR2YvUVk4ZTJXNmdMWko4aVM3MXlYb0JQNFpEc2lLSXd4ajFsenYyVFlXWnNSL3EKd28xSzBxZ1NzOXJJVEVkWDVqampycHBYWTdobHNPMGVKQ2JBRG0weEtnU1hMcFQycnJzUnJ2OFllRXFvZTRMaQpDOFd6RjZZRlh1U3RHR1E4SXlxbjdPaTN5aVU2WFc3OTl2cFpIeHJlaERYaytDalZuU0ZXWkVPUHg3cENpam9SCnlXb0gyUmR6QVpQczdVdVJWOUdGWWFQeHRudmttNVdVZDVTdWVCNlMxT2E4dVZ3UnpyeXl6WkRjdG0xdWs1VjIKUE0zLzFqbFJMbFJzTWxSeHdZUDRzaFMzVlhjTkdGYjkvbzkvTjkzbitKZUFpSGd4YU5pQjN6YVV0a05XWWs0Vgozang2d0psTythOUNxdGJJeXg2ZzdyTHhOanVqRFpRZTZGcUdsMzVkVDR5MHA2UmVuUWQ4b1p5aWw3dlpqSkJaCjluTWRJblMyU05wWUZFclBsb25rdXNZKzZsam9TbFNLMXVSRmd2S3dzeGE3RmROMXZWSnRJQk9qdVJzSk9DaHYKOTB2K0ZEQWwxSnNZVUNPUnByUmtMWXB2TWI4Q1BZaUlzb3JmTUdKNnI3NktYUEIzRS9xejRmaWJ1UmZVeWJxMgp5eGxRTVJKb216d1BPemUrbWRQUU5Hd3VTTjU0VnByYXhoNGFpcWtaUVBsSWpRb1dFaFVKRWxMb0NtQXZ4TmtxCmRBcVZJMXZ3cS9FRXFBTEh3amJKRXIwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=
    X-Smaak-Identifier: service-provider-public
    X-Smaak-Route-Info: 
    X-Smaak-Psk: 917e5f9bcf6d7c20a338d8a39bbf79ef
    X-Smaak-Expires: 1435225695
    X-Smaak-Nonce: 7211840395
    X-Smaak-Encrypt: false
    Content-Type: text/plain
    Content-Length: 20
    ... (redacted)
    {"index1":"data1"}

### Encrypted
    POST http://service-provider-internal:9393/secure-service HTTP/1.1
    Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3
    Accept: */*
    User-Agent: Ruby
    Authorization: Signature keyId="rsa-key-1",algorithm="rsa-sha256", headers="host date digest x-smaak-recipient x-smaak-identifier x-smaak-psk x-smaak-expires x-smaak-nonce x-smaak-encrypt content-length", signature="Y9v95p/rUAp3mmrZHKKvc4FVcDkCQuBVqArvhu70REQrIuHjJ2HDdS2xcQc1t41Ff+lRhO1aWf60cd+Be+1Q/8qsm5G35S66R9sQVr79h/zXovsimWw+GWmHj/d2RecgvGC9SXLRLchPSibYWiV1H5UlkCSqZEYevwFf17LlAk6mRVvFzcB50F+mYglcAFMQhFQI68JMN6CJWUrp09q5DH44WlsaCwUdmbn7pVAnbO6z45OtHPBjVoHtSFkGeFqhndkSRiXWrd9joXPqCb4VRUNG+NZk/9gU17yxkg63cheurf29EmRjAMDkP3nd/VGseOjNzm6MHjdgF9qrQxoQLleNb/lZcZB/ldCimR3AV0thu21NcSpOr1dIlKZX0oyiUOijPXCjXiOEtfO2wqsRk42c8b8nLJJUnFoDvWLQrY7ZFWnzeuu6OPVZQELcSsXokssz8Wsa+RjWo4HoQzfRi12/P1fDZVgj5EkNfUK/R/3ROR11XqdRaIiSXU8SIkof7iCe/2nGOLQNDmhQB6DWKRbN6Sl6bKB00Wto0t1yeeDyLcTrCDmJpKGS3L8hC671cT2f8nv4zHeDZUCqEVdvbcpbOILh9BxoxtLkhOhoAamdebOeOESDQEHwPvXHg9e46cQjGkdMxNgO/CyhSzVM6I5P60Sbn6ppHgsZ5w8ymPA="
    Host: service-provider-internal
    Date: 2015-06-25 09:45:34 GMT
    Digest: SHA-256=3f4502e658dd304d4cd1004a83935ede11692751011a410134ba861a1b55df92
    X-Smaak-Recipient: LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxL2tiYjdBNWllQWV1WlBBVnI3MAo5cjl1TkFzc2dmYkdjeGMzZTc3RDNndkY4U2tzbURNQmQyTUt5TUh0ZjBrM1pqSVdZemJJVG5jQXM1Nnd4cmRSClhiVHpIZnhjMll1dDMwd0ljR2YvUVk4ZTJXNmdMWko4aVM3MXlYb0JQNFpEc2lLSXd4ajFsenYyVFlXWnNSL3EKd28xSzBxZ1NzOXJJVEVkWDVqampycHBYWTdobHNPMGVKQ2JBRG0weEtnU1hMcFQycnJzUnJ2OFllRXFvZTRMaQpDOFd6RjZZRlh1U3RHR1E4SXlxbjdPaTN5aVU2WFc3OTl2cFpIeHJlaERYaytDalZuU0ZXWkVPUHg3cENpam9SCnlXb0gyUmR6QVpQczdVdVJWOUdGWWFQeHRudmttNVdVZDVTdWVCNlMxT2E4dVZ3UnpyeXl6WkRjdG0xdWs1VjIKUE0zLzFqbFJMbFJzTWxSeHdZUDRzaFMzVlhjTkdGYjkvbzkvTjkzbitKZUFpSGd4YU5pQjN6YVV0a05XWWs0Vgozang2d0psTythOUNxdGJJeXg2ZzdyTHhOanVqRFpRZTZGcUdsMzVkVDR5MHA2UmVuUWQ4b1p5aWw3dlpqSkJaCjluTWRJblMyU05wWUZFclBsb25rdXNZKzZsam9TbFNLMXVSRmd2S3dzeGE3RmROMXZWSnRJQk9qdVJzSk9DaHYKOTB2K0ZEQWwxSnNZVUNPUnByUmtMWXB2TWI4Q1BZaUlzb3JmTUdKNnI3NktYUEIzRS9xejRmaWJ1UmZVeWJxMgp5eGxRTVJKb216d1BPemUrbWRQUU5Hd3VTTjU0VnByYXhoNGFpcWtaUVBsSWpRb1dFaFVKRWxMb0NtQXZ4TmtxCmRBcVZJMXZ3cS9FRXFBTEh3amJKRXIwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=
    X-Smaak-Identifier: service-provider-public
    X-Smaak-Route-Info: 
    X-Smaak-Psk: 917e5f9bcf6d7c20a338d8a39bbf79ef
    X-Smaak-Expires: 1435225536
    X-Smaak-Nonce: 1443964335
    X-Smaak-Encrypt: true
    Content-Type: text/plain
    Content-Length: 684
    ... (redacted)
    fBkLECsy+UXmfx08eoFf45dtRgzkOCsoH2yh3CjsnSpiPKuXz+O5KVYvM/VpWrtYs11h5rwl563wwDoLuSQLgWzeiNoyJ4jttqcawVLG+


## Installation

Add this line to your application's Gemfile:

    gem 'smaak'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smaak

## Contributing

  Please send feedback and comments to the author at:

  Ernst van Graan <ernstvangraan@gmail.com>

  Thanks to Sheldon Hearn for review and great ideas that unblocked complex challenges (https://rubygems.org/profiles/sheldonh).

  This gem is sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za
