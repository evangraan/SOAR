module Converse
  class API
    attr_reader :broker

    def initialize(broker)
      @broker = broker
    end
  end
end
