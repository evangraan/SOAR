module SoarAuthentication
  class Authentication
    attr_accessor :request

    def initialize(request)
      @request = request
    end

    def authenticated?
      session_has_user? or dev_session?
    end

    def identifier
      return "developer" if dev_session?
      identifier = @request.session['user']
      identifier ||= @request.env['REMOTE_USER']
      identifier
    end

    private

    def session_has_user?
      ((not @request.session['user'].nil?) and (@request.session['user'] != '') or
       (not @request.env['REMOTE_USER'].nil?) and (@request.env['REMOTE_USER'] != ''))
    end

    def dev_session?
      (ENV['RACK_ENV'] == 'development')
    end
  end
end