require File.dirname(__FILE__) + '/spec_helper.rb'

module FunnelCake::UserStates
  def initialize_states
    # do nothing
  end
end

describe "using has_funnel on a User model" do
  class TestUser < ActiveRecord::Base
    set_table_name :users
  end
  class Analytics::Event < ActiveRecord::Base
  end
  class Analytics::Visitor < ActiveRecord::Base
  end

  before(:each) do
    TestUser.stub!(:has_one)
  end
  describe "for the User class" do
    it "should add the association for funnel visitor" do
      TestUser.should_receive(:has_one).with(:visitor, {:class_name=>"Analytics::Visitor", :dependent=>:destroy})
      TestUser.send(:has_funnel, :visitor_class_name=>"Analytics::Visitor")
    end
  end
end

