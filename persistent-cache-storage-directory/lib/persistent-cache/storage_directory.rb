require 'persistent-cache/storage_api'
require 'persistent-cache/version'

module Persistent
  class StorageDirectory < Persistent::Storage::API
    CACHE_FILE = "cache.gz" unless defined? CACHE_FILE; CACHE_FILE.freeze

    attr_accessor :storage_root

    def initialize(storage_details)
      raise ArgumentError.new("Storage details not provided") if storage_details.nil? or storage_details == ""
      @storage_root = storage_details
      connect_to_database
    end

    def connect_to_database
      FileUtils.makedirs([@storage_root]) if not File.directory?(@storage_root)
    end

    def save_key_value_pair(key, value, timestamp = nil)
      prepare_to_store_key_value(key, value, timestamp)
      store_key_value(key, value, get_time(timestamp)) if not value.nil?
    end

    def lookup_key(key)
      validate_key(key)
      return [] if not File.exists? compile_value_path(key)
      lookup_key_value_timestamp(key)
    end

    def delete_entry(key)
      validate_key(key)
      FileUtils.rm_rf(compile_key_path(key))
    end

    def size
      count = Dir::glob("#{@storage_root}/**/#{CACHE_FILE}").size
    end

    def keys
      return [] if size == 0
      list_keys_sorted
    end

    def clear
      keys.each do |key|
        delete_entry(key[0])
      end
    end

    def get_value_path(key)
      validate_key(key)

      return nil if not key_cached?(key)

      compile_value_path(key)
    end

    def get_value_path_even_when_not_cached(key)
      compile_value_path(key)
    end

    def key_cached?(key)
      # don't read the value here, as it may be very large - rather look whether the key is present
      File.exists? compile_key_path(key)
    end

    private

    def list_keys_sorted
      result = []
      append_keys(result).sort
    end

    def append_keys(result)
      get_key_directories.each do |dir|
        result << extract_key_from_directory(dir)
      end
      result
    end

    def get_key_directories
      subdirectories = Dir::glob("#{@storage_root}/**/")
      #exclude the storage root directory itself
      subdirectories[1..-1]
    end

    def extract_key_from_directory(dir)
      key = dir.match(/#{@storage_root}\/(\w+)\//)[1]
      [key]
    end

    def compile_key_path(key)
      "#{@storage_root}/#{key}"
    end

    def compile_value_path(key)
      "#{compile_key_path(key)}/#{CACHE_FILE}"
    end

    def validate_save_key_value_pair(key, value)
      validate_key(key)
      raise ArgumentError.new("Only string values allowed") if not value.is_a?(String)
    end

    def lookup_key_value_timestamp(key)
      result = [[],[]]
      data = File.read(compile_value_path(key))
      format_value_timestamp(result, data)
    end

    def format_value_timestamp(result, data)
      result[0][0] = data.lines.to_a[1..-1].join
      result[0][1] = data.lines.to_a[0..0].join.split("\n")[0]
      result
    end

    def validate_key(key)
      raise ArgumentError.new("Only string keys allowed") if not key.is_a?(String)
      root_path = Pathname.new(File.absolute_path(@storage_root))
      key_path = Pathname.new(File.absolute_path(compile_key_path(key)))
      relative = key_path.relative_path_from(root_path).to_s
      raise ArgumentError.new("key is outside of storage_root scope") if relative.start_with?("..")
      raise ArgumentError.new("key is the same as storage_root") if relative == "."
    end

    def empty_key_value(key)
      FileUtils.makedirs([compile_key_path(key)]) if not File.exists?(compile_key_path(key))
      FileUtils.rm_f(compile_value_path(key))
    end

    def get_time(timestamp)
      timestamp.nil? ? Time.now.to_s : timestamp.to_s
    end

    def prepare_to_store_key_value(key, value, timestamp)
      validate_save_key_value_pair(key, value)
      delete_entry(key)
      empty_key_value(key)
    end

    def store_key_value(key, value, timestamp)
      tempfile = Tempfile.new("store_key_value")
      store_value_timestamp_in_file(value, timestamp, tempfile)
      sync_cache_value(key, tempfile)
    end

    def sync_cache_value(key, tempfile)
      target = compile_value_path(key)
      FileUtils.rm_f(target)
      FileUtils.move(tempfile.path, target)
    end

    def store_value_timestamp_in_file(value, timestamp, tempfile)
      output = File.open(tempfile, 'a')
      write_value_timestamp(output, value, timestamp)
      output.close
    end

    def write_value_timestamp(output, value, timestamp)
      # Have to be explicit about writing to the file. 'puts' collapses newline at the end of the file and
      # so does not guarantee exact replication of 'value' on lookup
      output.write(timestamp)
      output.write("\n")
      output.write(value)
      output.flush
    end
  end
end
