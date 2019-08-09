require 'spec_helper'

class ItemUnderTest < Persistent::Storage::API
  def initialize(storage_details)
    super(storage_details)
  end

  def save_key_value_pair(key, value, timestamp = nil)
    super(key, value, timestamp)
  end

  def lookup_key(key)
    super(key)
  end

  def delete_entry(key)
    super(key)
  end

  def size()
    super()
  end

  def keys()
    super()
  end

  def clear()
    super()
  end
end

describe Persistent::Storage::API do
  before :each do
    @iut = ItemUnderTest.new({})
  end

  context "when using as a base class for a Persistent::Cache storage provider" do
    it 'has a version number' do
      expect(Persistent::Storage::VERSION).not_to be nil
    end

    it "should accept storage details when initialized" do
    end

    it "should raise a NotImplementedError when asked to save a key value pair" do
      expect{
        @iut.save_key_value_pair('key', 'value', nil)
      }.to raise_error NotImplementedError
    end

    it "should raise a NotImplementedError when asked to look up a key" do
      expect{
        @iut.lookup_key('key')
      }.to raise_error NotImplementedError
    end

    it "should raise a NotImplementedError when asked to delete an entry" do
      expect{
        @iut.delete_entry('key')
      }.to raise_error NotImplementedError
    end

    it "should raise a NotImplementedError when asked for its size" do
      expect{
        @iut.size()
      }.to raise_error NotImplementedError
    end

    it "should raise a NotImplementedError when asked for its keys" do
      expect{
        @iut.keys()
      }.to raise_error NotImplementedError
    end

    it "should raise a NotImplementedError when asked to clear" do
      expect{
        @iut.clear()
      }.to raise_error NotImplementedError
    end
  end
end
