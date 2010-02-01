require "#{File.dirname(__FILE__)}/../spec_helper"

describe ServerList do

  before do
    @servers = [
      {
        "test1"=>
          {"roles"=>["location/home", "app/production/db"],
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

  describe "accessing by hostname" do
    
    it "should return the info for the 'test1'" do
      @server_list = ServerList.new('test1', @servers)
      @server_list['test1']['server'].should == "192.0.32.10"
    end
    
    it "should return the info for the 'group2' relative to 'group1'" do
      @server_list = ServerList.new('group1', @servers)
      @server_list['group2']['server'].should == "192.0.32.13"
    end

    it "should return nil if the hostname doesn't exist" do
      @server_list = ServerList.new('group1', @servers)
      @server_list['unkown'].should be_nil
    end
    
    it "should return nil if the hostname is in a different group" do
      @server_list = ServerList.new('group1', @servers)
      @server_list['test1'].should be_nil
    end
  end

  describe "finding roles" do
    
    it "should find all the matching roles within the group" do
      @server_list = ServerList.new('group1', @servers)
      @server_list.by_role('location/colo').keys.should == ['group1', 'group2']
    end

    it "should only match roles within the group" do
      @server_list = ServerList.new('test1', @servers)
      @server_list.by_role('app/production/db').keys.should == ['test1']
    end

    it "should return an empty list of the role isn't found" do
      @server_list = ServerList.new('group1', @servers)
      @server_list.by_role('unknown/role').keys.should be_empty
    end

  end

end
