require "spec_helper"
require "broker"

module Converse
  describe Broker do
    before :each do
      @iut = Broker.new
    end

    context "when constructed" do
      it "should facilitate memory of a domain language indicator" do
        @iut.domain_language = "hosting"
        @iut.domain_language.should == "hosting"
      end
    end

    context "serving as an abstract base class" do
      it "should do have a method open_topic that takes concern and action and does nothing" do
        result = @iut.open_topic("concern", "action")
        result.nil?.should == true
      end

      it "should do have a method broker_conversation that takes a topic and does nothing" do
        result = @iut.broker_conversation("topic")
        result.nil?.should == true
      end

      it "should do have a method translate_response that takes a response and transparently returns it" do
        result = @iut.translate_response("response")
        result.should == "response"
      end
    end

    context "when facilitating a discussion" do
      it "should open the topic and broker the conversation" do
        class BrokerInterceptor < Broker
          attr_accessor :topic_opened
          attr_accessor :conversation_brokered

          def open_topic(concern, action)
            @topic_opened = true
          end

          def broker_conversation(topic)
            @conversation_brokered = true
          end
        end

        @iut = BrokerInterceptor.new
        @iut.discuss("concern", "action")
        @iut.topic_opened.should == true
        @iut.conversation_brokered.should == true
      end
    end
  end
end