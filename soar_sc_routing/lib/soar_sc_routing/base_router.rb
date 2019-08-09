require 'soar_aspects'

module SoarScRouting
  class BaseRouter
    attr_reader :route_meta

    def initialize(route_meta)
      @route_meta = route_meta
    end

    def route(request)
      route_path(request)

    rescue => ex
      excepted(ex)
    end

    def redirect_to(url, http_code = 302)
      [http_code, {'Location' => url, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    end

    protected

    def not_found
      raise NotImplementedError.new "Implement not found renderer"
    end

    def excepted(ex)
      raise NotImplementedError.new "Implement exception renderer: #{ex}"
    end

    private

    def debug(message, flow_identifier)
      auditing = SoarAspects::Aspects::auditing
      if auditing
        auditing.debug(message, flow_identifier)
      else
        $stderr.puts(message)
      end
    end

    def route_matched_path(request, path)
      debug("#{@route_meta.name} matched #{path}",request.params['flow_identifier'])
      http_code, content_type, body = @route_meta.routing[path].call(request)
      debug("controller returned #{http_code}, #{content_type}", request.params['flow_identifier'])
      return [http_code, content_type, body]
    end

    def route_path(request)
      debug("#{@route_meta.name} attempting to match #{request.path}",request.params['flow_identifier'])
      @route_meta.routing.each do |path, block|
        matches = Regexp.new(path).match(request.path)
        if matches && request_verb_matches_route_verb?(request,@route_meta.lexicon)
          request.define_singleton_method(:regex_matches) { return matches.to_a }
          return route_matched_path(request, path)
        end
      end
      debug("no match to #{request.path} on router #{@route_meta.name}",request.params['flow_identifier'])
      not_found
    end

    private

    def request_verb_matches_route_verb?(request,path_lexicon)
      return false if path_lexicon.nil? or path_lexicon[request.path].nil?
      path_lexicon[request.path]['method'].include?(request.env['REQUEST_METHOD'])
    end
  end
end
