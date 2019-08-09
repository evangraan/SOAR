require "spec_helper"
require "api"

module Converse
  describe API do
    context "when constructed with a broker" do
      it "should remember the broker" do
        @broker = "broker"
        @iut = API.new(@broker)
        @iut.broker.should == @broker
      end
    end
  end
end