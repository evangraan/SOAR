module SoarSr
  class ThreadedHandler < Handler
    include Jsender
    attr_accessor :max_threads

    def initialize(urns, uddi, credentials, registry, max_threads = 15)
      super(urns, uddi, credentials, registry)
      @@mutex = Mutex.new
      @max_threads = max_threads
    end

    protected

    def join_threads(threads)
      threads.each do |t|
        t.join
      end
    end

    def join_on_max_threads(threads)
      if threads.count == @max_threads
        join_threads(threads)
        threads = []
      end
      threads
    end    
  end
end
