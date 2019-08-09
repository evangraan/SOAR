require "spec_helper"
require "interaction"

module Converse
  describe Interaction do
    before :each do
      @iut = Converse::Interaction.new
      @broker = "test broker"
      @concern = "test concern"
      @action = "action"
      @substance = "substance"
      @conversation = "conversation"
    end

    context "on construction" do
      it "should have all attributes set to nil" do
        @iut.broker.nil?.should == true
        @iut.concern.nil?.should == true
        @iut.action.nil?.should == true
        @iut.substance.nil?.should == true
        @iut.conversation.nil?.should == true
        @iut.should_i_ask.nil?.should == true
      end
    end

    context "when asked to discuss a concern with a broker" do
      it "should remember the broken and concern and return the interaction" do
        out = @iut.discuss_with_broker_concerning(@broker, @concern)
        @iut.broker.should == @broker
        @iut.concern.should == @concern
        out.should == @iut
      end
    end

    context "when configured to ask a broker about a concern" do
      it "should remember the broker and concern, and the fact that it should ask, and return the interaction" do
        out = @iut.ask_broker_concerning(@broker, @concern)
        @iut.broker.should == @broker
        @iut.concern.should == @concern
        @iut.should_i_ask.should == true
        out.should == @iut
      end
    end

    context "when configured to tell a broker about a concern" do
      it "should remember the broker and concern, and the fact that it should tell, and return the interaction" do
        out = @iut.tell_broker_concerning(@broker, @concern)
        @iut.broker.should == @broker
        @iut.concern.should == @concern
        @iut.should_i_ask.should == false
        out.should == @iut
      end
    end

    context "when configured to ask a broker" do
      it "should remember the broker and the fact that it should ask and return the interaction (ask_broker)" do
        out = @iut.ask_broker(@broker)
        @iut.broker.should == @broker
        @iut.should_i_ask.should == true
        out.should == @iut
      end

      it "should remember the fact that it should ask and return the interaction (by_asking)" do
        out = @iut.by_asking
        @iut.should_i_ask.should == true
        out.should == @iut
      end
    end

    context "when configured to tell a broker" do
      it "should remember the broker and the fact that it should tell and return the interaction (tell_broker)" do
        out = @iut.tell_broker(@broker)
        @iut.broker.should == @broker
        @iut.should_i_ask.should == false
        out.should == @iut
      end

      it "should remember the fact that it should tell and return the interaction (by_saying)" do
        out = @iut.by_saying
        @iut.should_i_ask.should == false
        out.should == @iut
      end
    end

    context "when asked to discuss with a broker" do
      it "should remember the broker and return the interaction" do
        out = @iut.discuss_with(@broker)
        @iut.broker.should == @broker
        out.should == @iut
      end
    end

    context "when raising a concern" do
      it "should remember the concern and return the interaction" do
        out = @iut.concerning(@concern)
        @iut.concern.should == @concern
        out.should == @iut
      end
    end

    context "when indicating an action" do
      it "should remember the action and return the interaction (about)" do
        out = @iut.about(@action)
        @iut.action.should == @action
        out.should == @iut
      end

      it "should remember the action and return the interaction (to)" do
        out = @iut.to(@action)
        @iut.action.should == @action
        out.should == @iut
      end
    end

    context "when provided with substance" do
      it "should remember the substance and return the interaction (detailed_by)" do
        out = @iut.detailed_by(@substance)
        @iut.substance.should == @substance
        out.should == @iut
      end

      it "should remember the substance and return the interaction (using)" do
        out = @iut.using(@substance)
        @iut.substance.should == @substance
        out.should == @iut
      end

      it "should remember the substance and return the interaction (with)" do
        out = @iut.with(@substance)
        @iut.substance.should == @substance
        out.should == @iut
      end
    end

    context "when engaging in conversation" do
      it "should ask the conversation to say when saying" do
        @iut.conversation = @conversation
        @conversation.should_receive(:say)
        @iut.say
      end

      it "should ask the conversation to ask when asking" do
        @iut.conversation = @conversation
        @conversation.should_receive(:ask)
        @iut.ask
      end

      it "should subscribe a simple logger to the conversation" do
        @iut.discuss_with(@broker)
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:say)
        @broker.should_receive(:open_topic)
        @broker.should_receive(:broker_conversation).and_return(@conversation)
        @broker.should_receive(:translate_response)
        @iut.discuss
      end

      it "should ask the broker to open the topic with the concern and action and construct a conversation" do
        @iut.discuss_with(@broker).concerning(@concern).about(@action)
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:say)
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @broker.should_receive(:translate_response)
        @iut.discuss
      end

      it "should ask the broker to translate the response received and then interpret the response" do
        @iut.discuss_with(@broker).concerning(@concern).about(@action)
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:say).and_return("response")
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @broker.should_receive(:translate_response).with("response").and_return("response")
        @iut.discuss.should == "response"
      end

      it "should call ask on the conversation when configured to ask" do
        @iut.discuss_with(@broker).concerning(@concern).about(@action).by_asking
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:ask).and_return("response")
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @broker.should_receive(:translate_response).with("response").and_return("response")
        @iut.discuss.should == "response"
      end
    end

    context "when evaluating responses" do
      it "should always indicate success" do
        @iut.success?("anything").should == true
      end
    end

    context "when handling error responses" do
      it "should return the response intact" do
        @iut.handle_error!("error").should == "error"
      end
    end

    context "when handling errors" do
      it "should call the error handling hook method" do
        @iut.stub(:success?).and_return(false)
        @iut.stub(:handle_error!).and_return "called"

        @iut.discuss_with(@broker).concerning(@concern).about(@action).by_asking
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:ask).and_return("response")
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @broker.should_receive(:translate_response).with("called").and_return("called")
        @iut.discuss.should == "called"
      end

      it "should return nil if the response is nil" do
        @iut.stub(:success?).and_return(false)

        @iut.discuss_with(@broker).concerning(@concern).about(@action).by_asking
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:ask).and_return(nil)
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @iut.discuss.nil?.should == true
      end

      it "should return the response if the response is not nil" do
        @iut.stub(:success?).and_return(false)

        @iut.discuss_with(@broker).concerning(@concern).about(@action).by_asking
        @conversation.should_receive(:subscribe)
        @conversation.should_receive(:ask).and_return("response")
        @broker.should_receive(:open_topic) do |concern, action|
          concern.should == "test concern"
          action.should == "action"
        end.and_return "topic"
        @broker.should_receive(:broker_conversation).with("topic").and_return(@conversation)
        @broker.should_receive(:translate_response).with("response").and_return("response")
        @iut.discuss.should == "response"
      end
    end
  end
end