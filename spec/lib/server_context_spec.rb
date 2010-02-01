require "#{File.dirname(__FILE__)}/../spec_helper"

describe ServerContext do

  describe "Getting IPs for roles" do

    before do
      @servers = [
        {
          "test1"=>
            {"roles"=>["location/home", "app/production/db", "app/production/web"],
            "server"=>"192.0.32.10",
            "mirror"=>"http://mirror.internode.on.net/pub/ubuntu/ubuntu/"}
            },
        {
          "test2"=>
            {"roles"=>["location/home", "app/production/db"],
            "server"=>"192.0.32.11",
            "mirror"=>"http://mirror.internode.on.net/pub/ubuntu/ubuntu/"}
            },
        {
          "group1"=>
          {"roles"=>["location/colo", "app/production/db"],
            "server"=>"192.0.32.12",
            "mirror"=>"http://mirror.internode.on.net/pub/ubuntu/ubuntu/"},
          "group2"=>
          {"roles"=>["location/colo", "app/production/web"],
            "server"=>"192.0.32.13",
            "mirror"=>"http://mirror.internode.on.net/pub/ubuntu/ubuntu/"}
        }
      ]

    end

    def server_context(hostname)
      @server_list = ServerList.new(hostname, @servers)
      ServerList.stub!(:read).and_return(@server_list)

      @context = ServerContext.new(hostname)
    end

    describe "when app and db are the same machine" do

      it "should return its own IP address for the role 'app/production/db'" do
        server_context('test1').ip_by_role('app/production/db').should == '192.0.32.10'
      end

      it "should return its own IP address for the role 'app/production/web'" do
        server_context('test1').ip_by_role('app/production/web').should == '192.0.32.10'
      end

      it "should raise an exception an undefined role" do
        lambda { server_context('test1').ip_by_role('app/db') }.should raise_error(ArgumentError)
      end

    end

    describe "when app and db are different machines" do

      it "should return the IP of the matching server in the group" do
        server_context('group2').ip_by_role('app/production/db').should == '192.0.32.12'
      end

    end

  end

end