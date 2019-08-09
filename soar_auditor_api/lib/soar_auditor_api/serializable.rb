module SoarAuditorApi
  class Serializable
    def initialize (data)
      @data = data
    end

    def serialize
      begin
        require "base64"
        utf8_data = @data.to_s.encode(Encoding::UTF_8)
        urlsafe_base64_data = Base64.urlsafe_encode64(utf8_data)
        "[serialized:#{urlsafe_base64_data}]"
      rescue
        raise SerializationError, "General failure serializing the object data"
      end
    end

    def to_s
      raise NotImplementedError, "Class must implement to_s method when extending Serializable"
    end
  end

  class SerializationError < StandardError
  end
end
