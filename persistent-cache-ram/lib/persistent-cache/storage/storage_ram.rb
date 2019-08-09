require "eh/eh"

module Persistent
  class StorageRAM
    attr_accessor :storage

    def initialize()
      @storage = {}
    end

    def save_key_value_pair(serialized_key, serialized_value, timestamp = nil)
      delete_entry(serialized_key)
      time_entry = timestamp.nil? ? Time.now.to_s : timestamp.to_s
      EH.retry!(:args => [serialized_key, serialized_value, time_entry]) do
        @storage[serialized_key] = {:value => serialized_value, :timestamp => time_entry}
      end
    end

    def lookup_key(serialized_key)
      EH.retry!(:args => [serialized_key]) do
        return [] if @storage[serialized_key].nil?
        [@storage[serialized_key][:value], @storage[serialized_key][:timestamp]]
      end
    end

    def delete_entry(serialized_key)
      EH.retry!(:args => [serialized_key]) do
        @storage.delete(serialized_key)
      end
    end

    def size
      EH.retry!(:args => []) do
        @storage.size
      end
    end

    def keys
      EH.retry!(:args => []) do
        return [] if @storage.keys == []
        [@storage.keys]
      end
    end

    def clear
      EH.retry!(:args => []) do
        @storage.clear
      end
    end
  end
end
