require "spec_helper"
require "comms/mysql/mysql_conversation"

module Converse
  describe MysqlConversation do
    before :each do
      @iut = MysqlConversation.new("mysql://user:pass@somewhere.com:7743/databasename")
      @client = "client"
    end

    context "on construction" do
      it "should parse the URI provided and extract the username, password and database" do
        setup_connection
        @iut.connect
      end
    end

    context "when asked to connect to the database" do
      it "should create a mysql client and attempt to connect" do
        setup_connection
        @iut.connect
      end
    end

    context "when asked to converse given a query" do
      it "should connect to the database and issue the query on converse" do
        setup_query
        @iut.converse
      end

      it "should connect to the database and issue the query on ask" do
        setup_query
        @iut.ask
      end

      it "should connect to the database and issue the query on say" do
        setup_query
        @iut.say
      end
    end

    def setup_query
      @iut.query = "SHOW DATABASES"
      setup_connection
      @client.should_receive(:query).with("SHOW DATABASES")
    end

    def setup_connection
      Mysql2::Client.should_receive(:new).with({:host => "somewhere.com",
                                                :port => 7743,
                                                :username => "user",
                                                :password => "pass",
                                                :database => "databasename"}).and_return(@client)
    end
  end
end