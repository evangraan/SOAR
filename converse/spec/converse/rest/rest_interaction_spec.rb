require "spec_helper"
require "rest/rest_interaction"

module Converse
  describe RESTInteraction do
    before :each do
      @iut = RESTInteraction.new
      @broker = "broker"
      @action = "action"
      @substance = "substance"
    end

    context "when asked to ask a broker about an action with substance" do
      it "should initialize the broker using an empty concern, the action and substance" do
        @iut.ask_broker_about(@broker, @action, @substance)
        @iut.broker.should == @broker
        @iut.concern.should == ""
        @iut.action.should == @action
        @iut.substance.should == @substance
      end
    end

    context "when asked to tell a broker about an action with substance" do
      it "should initialize the broker using an empty concern, the action and substance" do
        @iut.tell_broker_to(@broker, @action, @substance)
        @iut.broker.should == @broker
        @iut.concern.should == ""
        @iut.action.should == @action
        @iut.substance.should == @substance
      end
    end

    context "when discussing" do
      class TestConversation
        attr_accessor :path
        attr_accessor :data

        def initialize
          @path =  "somewhere.com/someplace"
        end

        def ask(data)
          @data = data
        end

        def say(path, data)
          @path = path
          @data = data
        end
      end

      it "should ask the conversation with path and parameters adapted" do
        @conversation = TestConversation.new
        @iut.conversation = @conversation
        @iut.substance = {:param_a => "value_a", :param_b => "value_b"}
        @iut.ask
        #cannot guarantee hash ordering, so check for includes
        @conversation.data.include?("somewhere.com/someplace?").should == true
        @conversation.data.include?("param_a=value_a").should == true
        @conversation.data.include?("param_b=value_b").should == true
        @conversation.data.include?("&").should == true
      end

      it "should say to the conversation with path and parameters adapted" do
        @conversation = TestConversation.new
        @iut.conversation = @conversation
        @iut.substance = {:param_a => "value_a", :param_b => "value_b"}
        @conversation.should_receive(:say) do |path, params|
          path.should == "somewhere.com/someplace"
          #cannot guarantee hash ordering, so check for includes
          params.include?("param_a=value_a").should == true
          params.include?("param_b=value_b").should == true
          params.include?("&").should == true
        end
        @iut.say
      end

    end

    context "when preparing for RESTful communication" do
      it "should compile a list of CGI compatible parameters and present it in a string output ready for HTTP communication" do
        result = @iut.compile_params({:param_a => "value_a", :param_b => "value_b"})
        #cannot guarantee hash ordering, so check for includes
        result.include?("param_a=value_a").should == true
        result.include?("param_b=value_b").should == true
        result.include?("&").should == true      end

      it "should compile a path and parameter string ready for HTTP communication" do
        result = @iut.path_with_params("somewhere.com/someplace", {:param_a => "value_a", :param_b => "value_b"})
        result.include?("somewhere.com/someplace?").should == true
        result.include?("param_a=value_a").should == true
        result.include?("param_b=value_b").should == true
        result.include?("&").should == true
      end

      it "should output the path if the list of parameters is empty" do
        result = @iut.path_with_params("somewhere.com/someplace", {})
        result.should == "somewhere.com/someplace"
      end

      it "should output the path if the list of parameters is nil" do
        result = @iut.path_with_params("somewhere.com/someplace", nil)
        result.should == "somewhere.com/someplace"
      end
    end

    context "when receiving a response" do
      class TestResponse
        attr_accessor :code
        attr_accessor :body
      end
      it "should return true if the response code is 200" do
        response = TestResponse.new
        response.code = "200"
        @iut.success?(response).should == true
      end

      it "should return false if the response code is 200" do
        response = TestResponse.new
        response.code = "404"
        @iut.success?(response).should == false
      end

      it "should transform the response by transparently returning the response" do
        @iut.format_response("dontchangeme").should == "dontchangeme"
      end

      it "should interpret the response by transparently returning the response" do
        response = TestResponse.new
        response.body = "dontchangeme"
        @iut.interpret_conversation(response).should == "dontchangeme"
      end

      it "should format an error response as an array with code and error body" do
        response = TestResponse.new
        response.code = "404"
        response.body = "this is an error"
        @iut.format_error(response).should == ["404", "this is an error"]
      end
    end

    context "as a validator" do
      it "should not raise an error if validation is in JSON format" do
        @iut.ensure_that({:param_a => "value_a", :param_b => "value_b"}.to_json)
        @iut.is_json.should
      end

      it "should raise an error if validation is not in JSON format" do
        @iut.ensure_that("nope")
        expect{ @iut.is_json }.to raise_error(ArgumentError)
      end
    end
  end
end



