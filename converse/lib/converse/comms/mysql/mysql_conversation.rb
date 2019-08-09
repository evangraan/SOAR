require "converse/comms/conversation"
require "mysql2"

module Converse
  class MysqlConversation < Conversation
    attr_writer :username
    attr_writer :password
    attr_writer :database
    attr_accessor :query

    def initialize(uri)
      super(uri)
      parsed = URI.parse(uri)
      @username = parsed.user
      @password = parsed.password
      @database = parsed.path.gsub(/\//, "")
    end

    def connect()
      @client = Mysql2::Client.new(:host => @host,
                                   :port => @port.to_f,
                                   :username => @username,
                                   :password => @password,
                                   :database => @database)
    end

    def converse
      connect()
      @client.query(@query)
    end

    def ask
      converse
    end

    def say
      converse
    end

  end
end