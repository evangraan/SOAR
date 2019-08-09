require "spec_helper"
require "rest/rest_broker"
require "comms/html/html_conversation"

module Converse
  describe RESTBroker do
    before :each do
      @iut = RESTBroker.new
      @iut.host = "somewhere.com"
      @iut.port = "8080"
    end

    context "when asked to broker a conversation given a topic" do
      it "should do broker an HTML conversation on the topic" do
        conversation = @iut.broker_conversation("topic")
        conversation.is_a?(HTMLConversation).should == true
        conversation.uri.should == "topic"
        conversation.username.nil?.should == true
        conversation.password.nil?.should == true
      end

      it "should configure the username if provided" do
        @iut.username = "user"
        conversation = @iut.broker_conversation("topic")
        conversation.is_a?(HTMLConversation).should == true
        conversation.uri.should == "topic"
        conversation.username.should == "user"
        conversation.password.nil?.should == true
      end

      it "should configure the password if provided" do
        @iut.password = "password"
        conversation = @iut.broker_conversation("topic")
        conversation.is_a?(HTMLConversation).should == true
        conversation.uri.should == "topic"
        conversation.username.nil?.should == true
        conversation.password.should == "password"
      end
    end

    context "when asked to open a topic with no concern" do
      it "should return host_and_port/action" do
        @iut.open_topic("", "action").should == "http://somewhere.com:8080/action"
        @iut.open_topic(nil, "action").should == "http://somewhere.com:8080/action"
      end
    end

    context "when asked to open a topic with a concern" do
      it "should return host_and_port/concern/action" do
        @iut.open_topic("concern", "action").should == "http://somewhere.com:8080/concern/action"
      end
    end

    context "when configuring" do
      it "should return host:port if port is specified" do
        @iut.host_and_port.should == "somewhere.com:8080"
      end

      it "should return host only if port is specified" do
        @iut.port = nil
        @iut.host_and_port.should == "somewhere.com"
      end

      it "should remember a host" do
        @iut.talks_to("somewhereelse.com")
        @iut.host.should == "somewhereelse.com"
      end

      it "should remember a port" do
        @iut.on_port("9090")
        @iut.port.should == "9090"
      end

      it "should remember a username" do
        @iut.authenticated_by("username")
        @iut.username.should == "username"
      end

      it "should remember a password" do
        @iut.with_password("password")
        @iut.password.should == "password"
      end

    end
  end
end
