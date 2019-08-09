require './spec/spec_helper.rb'

describe Smaak::RackAdaptor do
  before :each do
    @env = {"CONTENT_LENGTH" => "25", "REQUEST_METHOD" => "POST", "PATH_INFO" => "/gems/smaak", "HTTP_X_SMAAK_ENCRYPT" => "false"}
    @request = Rack::Request.new(@env)
    
    @iut = Smaak::RackAdaptor.new(@request)
  end

  context "when initialized" do
    it "should remember the request provided" do
      expect(@iut.request).to eq(@request)
    end

    it "should raise an ArgumentError if request is not a Rack::Request" do
      expect{
        Smaak::NetHttpAdaptor.new("notarequest")
      }.to raise_error ArgumentError, "Must provide a Net::HTTPRequest"
      expect{
        Smaak::NetHttpAdaptor.new(nil)
      }.to raise_error ArgumentError, "Must provide a Net::HTTPRequest"
    end
  end

  context "when asked for a header" do
    it "should return an ArgumentError if the header is blank" do
      expect {
        @iut.header("")
      }.to raise_error ArgumentError, "Header must be a non-blank string"
      expect {
        @iut.header("  ")
      }.to raise_error ArgumentError, "Header must be a non-blank string"
    end

    it "should raise and ArgumentError if the header is not a string" do
      expect {
        @iut.header({:a => 'A'})
      }.to raise_error ArgumentError, "Header must be a non-blank string"
    end

    it "return the value of the requested header" do
      expect(@iut.header("content-length")).to eq("25")
      expect(@iut.header("x-smaak-encrypt")).to eq("false")
    end

    it "should translate the header from the Rack HTTP_header index in the Rack upcase" do
      expect(@iut.header("x-smaak-encrypt")).to eq("false")
    end

    it "should translate the header from the Rack underscore index" do
      expect(@iut.header("x-smaak-encrypt")).to eq("false")
    end

    it "should ignore header case" do
      expect(@iut.header("x-SMAAK-encrypt")).to eq("false")
    end
 
    it "should understand that content-length does not have HTTP_ prepended in the rack env" do
      expect(@iut.header("content-length")).to eq("25")
    end
 
    it "should understand that request-method does not have HTTP_ prepended in the rack env" do
      expect(@iut.header("request-method")).to eq("POST")
    end
  end

  context "when asked for request attributes" do
    it "should provide an accessor to the path" do
      expect(@iut.path).to eq("/gems/smaak")
    end

    it "should provide an accessor to the method" do
      expect(@iut.method).to eq("POST")
    end
  end

  context "when asked for the body" do
    it "should return the request body" do
      @request.body
    end
  end
end
