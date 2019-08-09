module SoarScRouting
  class Resource
    attr_accessor :description
    attr_accessor :method
    attr_accessor :id
    attr_accessor :params
    attr_accessor :input
    attr_accessor :output
 
    def initialize(description, id, method = 'GET', params = nil, input = nil, output = nil)
      @description = description
      @id = id
      @method = method
      @params = params
      @input = input
      @output = output
    end

    def content
      {
        'doc' => @description,
        'method' => @method,
        'id' => @id,
        'params' => @params
      }
    end
  end
end