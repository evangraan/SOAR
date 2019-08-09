require './spec/spec_helper.rb'

describe Smaak::Cavage04 do
  context "when signing headers" do
    before :all do
      @test_server_private_key = OpenSSL::PKey::RSA.new(4096)
    end

    before :each do
      @request = Net::HTTP::Post.new("http://rubygems.org:80/gems/smaak")
      @request.body = "body-data"
      @adaptor = Smaak::NetHttpAdaptor.new(@request)
      @iut = Smaak::Cavage04.new(@adaptor)
      @test_token_life = 10
      @test_nonce = 1234567890
      @test_expires = Time.now.to_i + @test_token_life
      @test_psk = "testpresharedkey"
      @test_server_public_key = @test_server_private_key.public_key
      @test_identity = "test-service"
      @test_identifier = 'test-service-1.cpt1.host-h.net'
      @test_route_info = 'identifier'
      @test_recipient = @test_server_public_key.export
      @test_encrypt = true
      @auth_message = Smaak::AuthMessage.new(@test_identifier, @test_route_info, @test_nonce, @test_expires, Smaak::Crypto.obfuscate_psk(@test_psk), @test_recipient, @test_encrypt)
    end

    context "as a specification implementation" do
      it "should publish the specification that it is based on" do
        expect(Smaak::Cavage04::SPECIFICATION.nil?).to eq(false)
        expect(Smaak::Cavage04::SPECIFICATION.is_a? String).to eq(true)
      end

      it "should provide a list of headers to be signed" do
        expect(Smaak::Cavage04.headers_to_be_signed.include? "host").to eq(true)
        expect(Smaak::Cavage04.headers_to_be_signed.include? "date").to eq(true)
        expect(Smaak::Cavage04.headers_to_be_signed.include? "digest").to eq(true)
        expect(Smaak::Cavage04.headers_to_be_signed.include? "content-length").to eq(true)
      end

      it "should indicate that the specification specific header (request-target) is to be signed" do
        expect(Smaak::Cavage04.headers_to_be_signed.include? "(request-target)").to eq(true)
      end
    end

    context "when initialized" do
      it "should raise an ArgumentError if no adaptor is provided" do
        expect {
          Smaak::Cavage04.new(nil)
        }.to raise_error ArgumentError, "Must provide a valid request adaptor"
      end

      it "should remember an adaptor provided" do
        expect(@iut.adaptor).to eq(@adaptor)
      end

      it "should set its headers to be signed to that of the specification and that of Smaak" do
        Smaak::Cavage04.headers_to_be_signed.each do |header|
          expect(@iut.headers_to_be_signed.include? header).to eq(true)
        end
        Smaak.headers_to_be_signed.each do |header|
          expect(@iut.headers_to_be_signed.include? header).to eq(true)
        end
      end
    end

    context "when asked to compile the authorization header with signature speficied" do
      it "should raise an ArgumentError if the signature is invalid" do
        expect {
          @iut.compile_auth_header(nil)
        }.to raise_error ArgumentError, "invalid signature"
        expect {
          @iut.compile_auth_header("")
        }.to raise_error ArgumentError, "invalid signature"
        expect {
          @iut.compile_auth_header("  ")
        }.to raise_error ArgumentError, "invalid signature"
        expect {
          @iut.compile_auth_header(978)
        }.to raise_error ArgumentError, "invalid signature"
      end

      context "when compiled" do
        before :each do
          @iut.adaptor.set_header("x-smaak-nonce", "12345")
          @iut.adaptor.set_header("x-smaak-encrypt", "true")
          @iut.compile_auth_header("signature")
        end
      
        it "should indicate the use of RSA keys" do
          expect(@iut.adaptor.request["authorization"].include?("keyId=\"rsa-key-1\"")).to eq(true)
        end

        it "should indicate the use of the rsa-sha256 algorithm" do
           expect(@iut.adaptor.request["authorization"].include?("algorithm=\"rsa-sha256\"")).to eq(true)
        end

        it "should insert the signature in the header" do
          expect(@iut.adaptor.request["authorization"].include?("signature=\"signature\"")).to eq(true)
        end

        it "should specify the order in which the headers that are signed appear in the request so that the signature can be verified by the receiver" do
          expect(@iut.adaptor.request["authorization"].include?("\"x-smaak-nonce x-smaak-encrypt\"")).to eq(true)
        end

        it "should set the authorization header on the adaptor to the compiled header" do
          expect(@iut.adaptor.request["authorization"]).to eq("Signature keyId=\"rsa-key-1\",algorithm=\"rsa-sha256\", headers=\"x-smaak-nonce x-smaak-encrypt\", signature=\"signature\"")
        end
      end
    end

    context "when asked to compile the headers to be included in the signature" do
      it "should use an empty string as body if the body is not provided" do
        @adaptor.request.body = nil
        expect(Digest::SHA256).to receive(:hexdigest).with("").and_return(Digest::SHA256.hexdigest(""))
        @iut.compile_signature_headers(@auth_message)
      end

      it "should set the authorization header to an empty string to preserve it at the top of the request headers list, in order not to interfere with the remaining headers' order" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["authorization"]).to eq("")
      end

      it "should set the host header to the adaptor request's host" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["host"]).to eq("rubygems.org")
      end

      it "should set the date header to the current timestamp, in GMT" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["date"]).to eq(Time.now.gmtime.to_s.gsub("UTC", "GMT"))
      end

      it "should set the digest header to a SHA256 hexadecimal digest of the body, labeled with SHA-256=" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["digest"]).to eq("SHA-256=#{Digest::SHA256.hexdigest(@request.body)}")
      end

      it "should set the x-smaak-recipient header to the base64 encoding of the message recipient's public key (source: auth_message), with no newlines" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["x-smaak-recipient"]).to eql(Base64.strict_encode64(@auth_message.recipient))
      end

      it "should set the x-smaak-psk header to the obfuscated pre-shared key (source: auth_message)" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["x-smaak-psk"]).to eql(@auth_message.psk)
      end

      it "should set the x-smaak-expires header to the expiry (source: auth_message)" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["x-smaak-expires"]).to eql("#{@auth_message.expires}")
      end

      it "should set the x-smaak-nonce header to the nonce (source: auth_message)" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["x-smaak-nonce"]).to eql("#{@auth_message.nonce}")
      end

      it "should set the x-smaak-encrypt header to the encryption choice (source: auth_message)" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["x-smaak-encrypt"]).to eql("#{@auth_message.encrypt}")
      end

      it "should set the content-type to text/plain" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["content-type"]).to eql("text/plain")
      end

      it "should set the content-length to the length of the adaptor's request body" do
        @iut.compile_signature_headers(@auth_message)
        expect(@iut.adaptor.request["content-length"]).to eql("#{@request.body.size}")
      end

      it "should compile and return (preserving insert order) the list of signature headers, pre-pended with the (request-target) header" do
         headers = @iut.compile_signature_headers(@auth_message).split("\n")
         expect(headers[0].split(":")[0]).to eql("(request-target)")
         expect(headers[1].split(":")[0]).to eql("host")
         expect(headers[2].split(":")[0]).to eql("date")
         expect(headers[3].split(":")[0]).to eql("digest")
         expect(headers[4].split(":")[0]).to eql("x-smaak-recipient")
         expect(headers[5].split(":")[0]).to eql("x-smaak-identifier")
         expect(headers[6].split(":")[0]).to eql("x-smaak-route-info")
         expect(headers[7].split(":")[0]).to eql("x-smaak-psk")
         expect(headers[8].split(":")[0]).to eql("x-smaak-expires")
         expect(headers[9].split(":")[0]).to eql("x-smaak-nonce")
         expect(headers[10].split(":")[0]).to eql("x-smaak-encrypt")
         expect(headers[11].split(":")[0]).to eql("content-length")
      end

      it "should not include int he list of signature headers non-signature headers" do
         content_type_present = false
         headers = @iut.compile_signature_headers(@auth_message).split("\n")
         headers.each do |header|
           content_type_present = true if header.split(":")[0] == "content-type"
         end
         expect(content_type_present).to eql(false)
      end
    end 
  end

  context "when receiving a signed header" do
    before :each do
      @env = \
{"CONTENT_LENGTH"=>"25", "CONTENT_TYPE"=>"text/plain", "GATEWAY_INTERFACE"=>"CGI/1.1", "PATH_INFO"=>"/secure-service", "QUERY_STRING"=>"", "REMOTE_ADDR"=>"10.0.0.224", "REMOTE_HOST"=>"service-provider-public", "REQUEST_METHOD"=>"POST", "REQUEST_URI"=>"http://service-provider-internal:9393/secure-service", "SCRIPT_NAME"=>"", "SERVER_NAME"=>"service-provider-internal", "SERVER_PORT"=>"9393", "SERVER_PROTOCOL"=>"HTTP/1.1", "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/2.0.0/2014-02-24)", "HTTP_ACCEPT_ENCODING"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "HTTP_ACCEPT"=>"*/*", "HTTP_USER_AGENT"=>"Ruby", "HTTP_AUTHORIZATION"=>"Signature keyId=\"rsa-key-1\",algorithm=\"rsa-sha256\", headers=\"host date digest x-smaak-recipient x-smaak-identifier x-smaak-route-info x-smaak-psk x-smaak-expires x-smaak-nonce x-smaak-encrypt content-length\", signature=\"RQgXQo+Fugz1ubgV1UAJvdPaNHiwTMtu0x+LNJ/7rvY5gaY5R88tUPtcFMzjRzw2QXtY5pettjfbq9LvISnW5MFG7p+goY4YsF4a6b7KgbU8RCAMLVyj4zWEIh/R+3WovuhcG8e5iLGN5/HGHkgDjZzi1a2WwU+tcwSwKBQ0BN+hKUV6haAHxUcNJ8bOgtnZZpSbD0megEmmBwiOjY5EsdM9wFMqGRrBWYV950xs/cPgO7Hjgq4kTnBiFC8Zkcz5zmkkokVE6VliNSPrqIZHm4fGk9UWyDYydlE+4z/wa4KrDs7/JXCQh+HF+BfSlnhG1xm9UT857o8Uz3j8ds4hvzUJyVcHX5B7wFln5szSFz5cdNFdMq6RP3e/TWGEV9J3sWi3pLymQog9jfkS1sjBSUxlc0Nh1hyiBFjybPZcbx6L77hsYV7dnCKF1z5UItvNj2JOkUCe+ppDkfhNxNkSUv9KBir+U+xJwDh+uyO/IAj8TB0cklsdnJNNHCDA4Mmi59RnA6uMsjOo6j7btkRF8nZmDvq0AWmgIUnwIWNWt13ecBH6u1Y03s5D09gX8sILKWuhC4oGEzjE7gBxrORn/MSPNAwAOsx/3ud4PFlOa7DGKApolpL0099w5QgFDqDYALujDdZC2GNgHCdoJqNLoMCEkyVWArvvgxtQ4Xq/0zU=\"", "HTTP_HOST"=>"service-provider-internal", "HTTP_DATE"=>"2015-06-23 13:40:07 GMT", "HTTP_DIGEST"=>"SHA-256=748957b58cc24d2bb9eb8f9c468571712a14f6a89ce936c0fb2d3c5016e4dbdc", "HTTP_X_SMAAK_RECIPIENT"=>"LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxL2tiYjdBNWllQWV1WlBBVnI3MAo5cjl1TkFzc2dmYkdjeGMzZTc3RDNndkY4U2tzbURNQmQyTUt5TUh0ZjBrM1pqSVdZemJJVG5jQXM1Nnd4cmRSClhiVHpIZnhjMll1dDMwd0ljR2YvUVk4ZTJXNmdMWko4aVM3MXlYb0JQNFpEc2lLSXd4ajFsenYyVFlXWnNSL3EKd28xSzBxZ1NzOXJJVEVkWDVqampycHBYWTdobHNPMGVKQ2JBRG0weEtnU1hMcFQycnJzUnJ2OFllRXFvZTRMaQpDOFd6RjZZRlh1U3RHR1E4SXlxbjdPaTN5aVU2WFc3OTl2cFpIeHJlaERYaytDalZuU0ZXWkVPUHg3cENpam9SCnlXb0gyUmR6QVpQczdVdVJWOUdGWWFQeHRudmttNVdVZDVTdWVCNlMxT2E4dVZ3UnpyeXl6WkRjdG0xdWs1VjIKUE0zLzFqbFJMbFJzTWxSeHdZUDRzaFMzVlhjTkdGYjkvbzkvTjkzbitKZUFpSGd4YU5pQjN6YVV0a05XWWs0Vgozang2d0psTythOUNxdGJJeXg2ZzdyTHhOanVqRFpRZTZGcUdsMzVkVDR5MHA2UmVuUWQ4b1p5aWw3dlpqSkJaCjluTWRJblMyU05wWUZFclBsb25rdXNZKzZsam9TbFNLMXVSRmd2S3dzeGE3RmROMXZWSnRJQk9qdVJzSk9DaHYKOTB2K0ZEQWwxSnNZVUNPUnByUmtMWXB2TWI4Q1BZaUlzb3JmTUdKNnI3NktYUEIzRS9xejRmaWJ1UmZVeWJxMgp5eGxRTVJKb216d1BPemUrbWRQUU5Hd3VTTjU0VnByYXhoNGFpcWtaUVBsSWpRb1dFaFVKRWxMb0NtQXZ4TmtxCmRBcVZJMXZ3cS9FRXFBTEh3amJKRXIwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=", "HTTP_X_SMAAK_IDENTIFIER"=>"service-provider-public", "HTTP_X_SMAAK_ROUTE_INFO"=>"", "HTTP_X_SMAAK_PSK"=>"917e5f9bcf6d7c20a338d8a39bbf79ef", "HTTP_X_SMAAK_EXPIRES"=>"1435066809", "HTTP_X_SMAAK_NONCE"=>"6457661831", "HTTP_X_SMAAK_ENCRYPT"=>"false", "HTTP_CONNECTION"=>"close"}
      @request = Rack::Request.new(@env)
      @adaptor = Smaak::RackAdaptor.new(@request)
      @iut = Smaak::Cavage04.new(@adaptor)
    end

    context "when asked to extract signature headers from a request" do
      it "should find the signature headers list in the authorization header return them separated using spaces" do
        expect(@iut.extract_signature_headers).to eq(\
"(request-target): post /secure-service\nhost: service-provider-internal\ndate: 2015-06-23 13:40:07 GMT\ndigest: SHA-256=748957b58cc24d2bb9eb8f9c468571712a14f6a89ce936c0fb2d3c5016e4dbdc\nx-smaak-recipient: LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxL2tiYjdBNWllQWV1WlBBVnI3MAo5cjl1TkFzc2dmYkdjeGMzZTc3RDNndkY4U2tzbURNQmQyTUt5TUh0ZjBrM1pqSVdZemJJVG5jQXM1Nnd4cmRSClhiVHpIZnhjMll1dDMwd0ljR2YvUVk4ZTJXNmdMWko4aVM3MXlYb0JQNFpEc2lLSXd4ajFsenYyVFlXWnNSL3EKd28xSzBxZ1NzOXJJVEVkWDVqampycHBYWTdobHNPMGVKQ2JBRG0weEtnU1hMcFQycnJzUnJ2OFllRXFvZTRMaQpDOFd6RjZZRlh1U3RHR1E4SXlxbjdPaTN5aVU2WFc3OTl2cFpIeHJlaERYaytDalZuU0ZXWkVPUHg3cENpam9SCnlXb0gyUmR6QVpQczdVdVJWOUdGWWFQeHRudmttNVdVZDVTdWVCNlMxT2E4dVZ3UnpyeXl6WkRjdG0xdWs1VjIKUE0zLzFqbFJMbFJzTWxSeHdZUDRzaFMzVlhjTkdGYjkvbzkvTjkzbitKZUFpSGd4YU5pQjN6YVV0a05XWWs0Vgozang2d0psTythOUNxdGJJeXg2ZzdyTHhOanVqRFpRZTZGcUdsMzVkVDR5MHA2UmVuUWQ4b1p5aWw3dlpqSkJaCjluTWRJblMyU05wWUZFclBsb25rdXNZKzZsam9TbFNLMXVSRmd2S3dzeGE3RmROMXZWSnRJQk9qdVJzSk9DaHYKOTB2K0ZEQWwxSnNZVUNPUnByUmtMWXB2TWI4Q1BZaUlzb3JmTUdKNnI3NktYUEIzRS9xejRmaWJ1UmZVeWJxMgp5eGxRTVJKb216d1BPemUrbWRQUU5Hd3VTTjU0VnByYXhoNGFpcWtaUVBsSWpRb1dFaFVKRWxMb0NtQXZ4TmtxCmRBcVZJMXZ3cS9FRXFBTEh3amJKRXIwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=\nx-smaak-identifier: service-provider-public\nx-smaak-route-info: \nx-smaak-psk: 917e5f9bcf6d7c20a338d8a39bbf79ef\nx-smaak-expires: 1435066809\nx-smaak-nonce: 6457661831\nx-smaak-encrypt: false\ncontent-length: 25")
      end

      it "should prepend the (request-target) header" do
        expect(@iut.extract_signature_headers[0..15]).to eq("(request-target)")
      end

      it "should return the signature headers in the order expressed in the signature, so that signature verification can succeed" do
        # host date digest x-smaak-recipient x-smaak-identifier x-smaak-route-info x-smaak-psk x-smaak-expires x-smaak-nonce x-smaak-encrypt content-length
        expect(@iut.extract_signature_headers).to eq(\
"(request-target): post /secure-service\nhost: service-provider-internal\ndate: 2015-06-23 13:40:07 GMT\ndigest: SHA-256=748957b58cc24d2bb9eb8f9c468571712a14f6a89ce936c0fb2d3c5016e4dbdc\nx-smaak-recipient: LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxL2tiYjdBNWllQWV1WlBBVnI3MAo5cjl1TkFzc2dmYkdjeGMzZTc3RDNndkY4U2tzbURNQmQyTUt5TUh0ZjBrM1pqSVdZemJJVG5jQXM1Nnd4cmRSClhiVHpIZnhjMll1dDMwd0ljR2YvUVk4ZTJXNmdMWko4aVM3MXlYb0JQNFpEc2lLSXd4ajFsenYyVFlXWnNSL3EKd28xSzBxZ1NzOXJJVEVkWDVqampycHBYWTdobHNPMGVKQ2JBRG0weEtnU1hMcFQycnJzUnJ2OFllRXFvZTRMaQpDOFd6RjZZRlh1U3RHR1E4SXlxbjdPaTN5aVU2WFc3OTl2cFpIeHJlaERYaytDalZuU0ZXWkVPUHg3cENpam9SCnlXb0gyUmR6QVpQczdVdVJWOUdGWWFQeHRudmttNVdVZDVTdWVCNlMxT2E4dVZ3UnpyeXl6WkRjdG0xdWs1VjIKUE0zLzFqbFJMbFJzTWxSeHdZUDRzaFMzVlhjTkdGYjkvbzkvTjkzbitKZUFpSGd4YU5pQjN6YVV0a05XWWs0Vgozang2d0psTythOUNxdGJJeXg2ZzdyTHhOanVqRFpRZTZGcUdsMzVkVDR5MHA2UmVuUWQ4b1p5aWw3dlpqSkJaCjluTWRJblMyU05wWUZFclBsb25rdXNZKzZsam9TbFNLMXVSRmd2S3dzeGE3RmROMXZWSnRJQk9qdVJzSk9DaHYKOTB2K0ZEQWwxSnNZVUNPUnByUmtMWXB2TWI4Q1BZaUlzb3JmTUdKNnI3NktYUEIzRS9xejRmaWJ1UmZVeWJxMgp5eGxRTVJKb216d1BPemUrbWRQUU5Hd3VTTjU0VnByYXhoNGFpcWtaUVBsSWpRb1dFaFVKRWxMb0NtQXZ4TmtxCmRBcVZJMXZ3cS9FRXFBTEh3amJKRXIwQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=\nx-smaak-identifier: service-provider-public\nx-smaak-route-info: \nx-smaak-psk: 917e5f9bcf6d7c20a338d8a39bbf79ef\nx-smaak-expires: 1435066809\nx-smaak-nonce: 6457661831\nx-smaak-encrypt: false\ncontent-length: 25")
      end
    end

    context "when asked to extract the signature from a request" do
      it "should extract only the signature field from the request" do
        expect(@iut.extract_signature).to eq("RQgXQo+Fugz1ubgV1UAJvdPaNHiwTMtu0x+LNJ/7rvY5gaY5R88tUPtcFMzjRzw2QXtY5pettjfbq9LvISnW5MFG7p+goY4YsF4a6b7KgbU8RCAMLVyj4zWEIh/R+3WovuhcG8e5iLGN5/HGHkgDjZzi1a2WwU+tcwSwKBQ0BN+hKUV6haAHxUcNJ8bOgtnZZpSbD0megEmmBwiOjY5EsdM9wFMqGRrBWYV950xs/cPgO7Hjgq4kTnBiFC8Zkcz5zmkkokVE6VliNSPrqIZHm4fGk9UWyDYydlE+4z/wa4KrDs7/JXCQh+HF+BfSlnhG1xm9UT857o8Uz3j8ds4hvzUJyVcHX5B7wFln5szSFz5cdNFdMq6RP3e/TWGEV9J3sWi3pLymQog9jfkS1sjBSUxlc0Nh1hyiBFjybPZcbx6L77hsYV7dnCKF1z5UItvNj2JOkUCe+ppDkfhNxNkSUv9KBir+U+xJwDh+uyO/IAj8TB0cklsdnJNNHCDA4Mmi59RnA6uMsjOo6j7btkRF8nZmDvq0AWmgIUnwIWNWt13ecBH6u1Y03s5D09gX8sILKWuhC4oGEzjE7gBxrORn/MSPNAwAOsx/3ud4PFlOa7DGKApolpL0099w5QgFDqDYALujDdZC2GNgHCdoJqNLoMCEkyVWArvvgxtQ4Xq/0zU=")
      end
    end
  end
end

