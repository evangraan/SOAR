require "spec_helper"
require 'rspec/mocks/standalone'

module Converse
  describe SimpleLogger do
    before :each do
      @iut = SimpleLogger.new
    end

    context "when notified" do
      it "should output the message to standard output" do
        @iut.stub!(:puts).with("testing")
        @iut.notify("testing")
      end
    end
  end
end