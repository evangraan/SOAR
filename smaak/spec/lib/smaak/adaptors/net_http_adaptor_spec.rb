require './spec/spec_helper.rb'

describe Smaak::NetHttpAdaptor do
  before :each do
    @request = Net::HTTP::Post.new("http://rubygems.org:80/gems/smaak")
    @request.body = "body-data"
    @iut = Smaak::NetHttpAdaptor.new(@request)
  end

  context "when initialized" do
    it "should remember the request provided" do
      expect(@iut.request).to eq(@request)
    end

    it "should raise an ArgumentError if request is not a Net::HTTPRequest" do
      expect{
        Smaak::NetHttpAdaptor.new("notarequest")
      }.to raise_error ArgumentError, "Must provide a Net::HTTPRequest"
      expect{
        Smaak::NetHttpAdaptor.new(nil)
      }.to raise_error ArgumentError, "Must provide a Net::HTTPRequest"
    end
  end

  context "when asked to set a header" do
    it "should raise an ArgumentError if the header is not a non-blank string" do
      expect {
        @iut.set_header("", "value")
      }.to raise_error ArgumentError, "Header must be a non-blank string"
      expect {
        @iut.set_header("  ", "value")
      }.to raise_error ArgumentError, "Header must be a non-blank string"
    end

    it "should raise and ArgumentError if the header is not a string" do
      expect {
        @iut.set_header({:a => 'A'}, "value")
      }.to raise_error ArgumentError, "Header must be a non-blank string"
    end

    it "should set the header on the request" do
      @iut.set_header("one", "1")
      @iut.set_header("two", "2")
      expect(@iut.request["one"]).to eq("1")
      expect(@iut.request["two"]).to eq("2")
    end
  end

  context "when asked to iterate all headers" do
    it "should iterate each header if there are headers set" do
      @iut.set_header("one", "1")
      @iut.set_header("two", "2")
      count = 0
      one = false
      two = false
      @iut.each_header do |header, value|
        count = count + 1
        one = true if header == "one" and value == "1"
        two = true if header == "two" and value == "2"
      end
      expect(count).to eq(5) # some default headers come with a vanilla request
      expect(one).to eq(true)
      expect(two).to eq(true)
    end

    it "should not iterate any headers if there are no headers set" do
      count = 0
      @iut.each_header do |_header, _value|
        count = count + 1
      end
      expect(count).to eq(3) # some default headers come with a vanilla request
    end
  end

  context "when asked for request attributes" do
    it "should provide an accessor to the host" do
      expect(@iut.host).to eq("rubygems.org")
    end

    it "should provide an accessor to the path" do
      expect(@iut.path).to eq("/gems/smaak")
    end

    it "should provide an accessor to the method" do
      expect(@iut.method).to eq("POST")
    end

    it "should provide an accessor to the body" do
      expect(@iut.body).to eq("body-data")
    end
  end

  context "when setting the body" do
    it "should set the request's body attribute" do
      @iut.body = "new body"
      expect(@iut.body).to eq("new body")
    end
  end
end
