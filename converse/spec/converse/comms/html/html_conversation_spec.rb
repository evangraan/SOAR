require "spec_helper"
require "comms/html/html_conversation"

module Converse
  describe HTMLConversation do
    class TestSubscriber
      attr_accessor :data

      def notify(message)
        @data = message
      end
    end

    class TestRequest
      attr_accessor :body
      attr_accessor :account
      attr_accessor :password

      def initialize
        @body = "body"
        basic_auth("account", "password")
      end

      def basic_auth(account, password)
        @account = account
        @password = password
      end
    end

    class TestResponse
      attr_accessor :body

      def initialize
        @body = "response body"
      end
    end

    before :each do
      @mock_connection = []
      @iut = HTMLConversation.new("http://somewhere.com:9876")
      @iut.username = "user"
      @iut.password = "password"
      @iut.use_ssl = false
      @subscriber = TestSubscriber.new
    end

    context "on construction" do
      it "should remember username, password, SSL should be forced to false" do
        @iut.username.should == "user"
        @iut.password.should == "password"
        @iut.use_ssl.should == false
      end

      it "should configure port to 80 if not provided" do
        @iut = HTMLConversation.new("http://somewhere.com")
        @iut.port.should == 80
      end
    end

    context "when configured" do
      it "should remember username, password, port and ssl" do
        @iut.username = "user2"
        @iut.password = "password2"
        @iut.use_ssl = true
        @iut.port = 443
        @iut.username.should == "user2"
        @iut.password.should == "password2"
        @iut.use_ssl.should == true
        @iut.port.should == 443
      end
    end

    context "when processing message notification" do
      it "should notify subscribers of requests when asked to" do
        @iut.subscribe(@subscriber)
        @iut.request = TestRequest.new
        @iut.populate_request("http://somewhere.com/something", "request data")
        @subscriber.should_receive(:notify).with("HTTP=>\nrequest\nrequest data\n")
        @iut.notify_subscribers_of_request("request")
      end

      it "should notify subscribers of responses" do
        @iut.subscribe(@subscriber)
        @iut.response = TestRequest.new
        @subscriber.should_receive(:notify).with("<=HTTP\nbody\n")
        @iut.notify_subscribers_of_response
      end
    end

    context "when asked to populate request data" do
      it "should set the request body to the data if there is data" do
        @iut.request = TestRequest.new
        @iut.populate_request("http://somewhere.com/something", "request data")
        @iut.request.body.should == "request data"
      end

      it "should not change the request body if no data is provided" do
        @iut.request = TestRequest.new
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.body.should == "body"

        @iut.request.body = nil
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.body.nil?.should == true
      end

      it "should fill in authentication information if available" do
        @iut.request = TestRequest.new
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.account.should == "user"
        @iut.request.password.should == "password"

        @iut.username = nil
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.account.nil?.should == true
        @iut.request.password.should == "password"

        @iut.username = "user"
        @iut.password = nil
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.account.should == "user"
        @iut.request.password.nil?.should == true

        @iut.username = nil
        @iut.request.account = nil
        @iut.request.password = nil
        @iut.populate_request("http://somewhere.com/something", nil)
        @iut.request.account.nil?.should == true
        @iut.request.password.nil?.should == true
      end

      it "should notify subscribers of the request update" do
        @iut.subscribe(@subscriber)
        @iut.request = TestRequest.new
        @subscriber.should_receive(:notify).with("HTTP=>\nhttp://somewhere.com/something\nbody\n")
        @iut.populate_request("http://somewhere.com/something", nil)
      end
    end

    context "when asked to connect" do
      it "should call Net::HTTP.start without SSL parameters if SSL is not configured" do
        @iut.use_ssl = false
        Net::HTTP.should_receive(:start) do |host, port|
          host.should == "somewhere.com"
          port.should == 9876
        end
        @iut.connect
      end

      it "should call Net::HTTP.start with SSL parameters if SSL is configured" do
        @iut.use_ssl = true
        Net::HTTP.should_receive(:start) do |host, port, ssl|
          host.should == "somewhere.com"
          port.should == 9876
          ssl.should == {:use_ssl=>"yes"}
        end
        @iut.connect
      end
    end

    context "when conversing" do
      it "should populate the request with the data provided, connect and issue the request, then notify subscribers with and return the response" do
        prepare_converse
        test_response
      end

      it "should create a Net:HTTP:Get request and converse when asking" do
        prepare_converse
        Net::HTTP::Get.should_receive(:new).with("http://newpath/go").and_return(@iut.request)
        @iut.ask "http://newpath/go", "some data"
      end

      it "should create a Net:HTTP:Post request and converse when saying" do
        prepare_converse
        Net::HTTP::Post.should_receive(:new).with("http://newpath/go").and_return(@iut.request)
        @iut.say"http://newpath/go", "some data"
      end

      def prepare_converse
        @iut.request = TestRequest.new
        @iut.subscribe(@subscriber)
        Net::HTTP.should_receive(:start).and_return(@mock_connection)
        @test_response = TestResponse.new
        @mock_connection.should_receive(:request).with(@iut.request).and_return(@test_response)
        @subscriber.should_receive(:notify).with("HTTP=>\nhttp://newpath/go\nsome data\n")
        @subscriber.should_receive(:notify).with("<=HTTP\nresponse body\n")
      end

      def test_response
        result = @iut.converse("http://newpath/go", "some data")
        @iut.request.body.should == "some data"
        result.should == @test_response
      end
    end
  end
end

