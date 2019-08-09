require 'smaak'

module SoarSmaak
  class Interpreter
    def self.smaak_request?(request)
      auth_header = ::Smaak::RackAdaptor.new(request).header("authorization")
      (not (auth_header.nil?)) and (auth_header.include?("x-smaak"))
    end  
  end
end