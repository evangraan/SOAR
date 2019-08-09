require "spec_helper"
require "comms/conversation"

module Converse
  describe Conversation do
    class TestSubscriber
      attr_accessor :data

      def notify(message)
         @data = message
      end
    end

    before :each do
      @iut = Conversation.new("http://somewhere.com:8081/something?parama=valuea")
    end

    context "when constructed with a URI" do
      it "should remember the URI and extract the host, port and path from the URI" do
        @iut.uri.should == "http://somewhere.com:8081/something?parama=valuea"
        @iut.host.should == "somewhere.com"
        @iut.port.should == 8081
        @iut.path.should == "/something"
      end

      it "should have no subscribers" do
        @iut.subscribers.size.should == 0
      end
    end

    context "as an abstract base class" do
      it "should raise an error on ask" do
        expect {@iut.ask}.to raise_error NotImplementedError
      end

      it "should raise an error on say" do
        expect {@iut.say}.to raise_error NotImplementedError
      end
    end

    context "when managing subscribers" do
      it "should append the subscriber to the list of subscribers" do
        @iut.subscribe(TestSubscriber.new)
        @iut.subscribe(TestSubscriber.new)
        @iut.subscribers.size.should == 2
      end

      it "should notify all subscribers when requested to do so" do
        a = TestSubscriber.new
        b = TestSubscriber.new
        @iut.subscribe(a)
        @iut.subscribe(b)
        a.data.nil?.should == true
        b.data.nil?.should == true
        @iut.notify_subscribers("somedata")
        a.data.should == "somedata"
        b.data.should == "somedata"
      end
    end
  end
end