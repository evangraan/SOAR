module Smaak
  class Utils
    def self.non_blank_string?(s)
      return false if s.nil?
      return false unless s.is_a? String
      return false if s.strip == ""
      return true
    end
  end
end
