require './spec/spec_helper.rb'

class Tester < Smaak::SmaakService
  attr_reader :configured

  def self.mutex
    @@mutex
  end

  def self.instance
    @@instance
  end

  def configure_services(_configuration = nil)
    @configured = true
  end
end

describe Smaak::SmaakService do
  before :all do
    @iut = Tester.get_instance
  end

  context "when initialized" do
    it "should instantiate itself and remember it" do
      expect(@iut.smaak_server.nil?).to eq(false)
      expect(@iut.smaak_server.is_a?(Smaak::Server)).to eq(true)
    end

    it "should call configure_service as an IOC seam" do
      expect(@iut.configured).to eq(true)
    end
  end

  context "when asked for an instance of itself" do
    it "should always return the same instance" do
      a = Smaak::SmaakService.get_instance
      b = Smaak::SmaakService.get_instance
      c = Smaak::SmaakService.get_instance
      expect(a).to eq(b)
      expect(b).to eq(c)
    end
  end

  context "as a singleton" do
    it "should implement the singleton pattern and be thread-safe" do
      expect(Tester.mutex.is_a? Mutex).to eq(true)
      expect(Tester.instance.nil?).to eq(false)
    end
  end
end
