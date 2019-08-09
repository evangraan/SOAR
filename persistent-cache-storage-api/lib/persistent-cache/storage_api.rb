require "persistent-cache/version"

module Persistent
  module Storage
    class API
      public 

      def initialize(storage_details)
      end

      protected

      def save_key_value_pair(key, value, timestamp = nil) abstract end

      def lookup_key(key) abstract end

      def delete_entry(key) abstract end

      def size() abstract end

      def keys() abstract end

      def clear() abstract end

      private

      def abstract
        raise NotImplementedError.new("#{self.class.name} is an abstract class.")
      end
    end
  end    
end
