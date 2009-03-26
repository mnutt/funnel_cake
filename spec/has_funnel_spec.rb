require 'rubygems'
require 'active_record'
require 'action_controller'
require File.dirname(__FILE__) + '/../init'

module FunnelCake::UserStates
  def initialize_states
    # do nothing
  end
end

describe "using has_funnel on a User model" do
  class TestUser < ActiveRecord::Base
  end
  class FunnelEvent < ActiveRecord::Base
  end
  class FunnelVisitor < ActiveRecord::Base
  end

  before(:each) do
    TestUser.stub!(:acts_as_funnel_state_machine)
    TestUser.stub!(:has_many)
    TestUser.stub!(:state)
    TestUser.stub!(:initialize_states)
    FunnelVisitor.stub!(:acts_as_funnel_state_machine)
    FunnelVisitor.stub!(:state)
    FunnelVisitor.stub!(:initialize_states)
    FunnelVisitor.stub!(:has_one)
  end
  describe "for the User class" do
    it "should add the association for funnel events" do
      TestUser.should_receive(:has_many).with(:funnel_events, {:class_name=>"FunnelEvent"})
      TestUser.send(:has_funnel)
    end
    it "should add the acts_as_state_machine directive" do
      TestUser.should_receive(:acts_as_funnel_state_machine).with(hash_including(:log_transitions=>true, :validate_on_transitions=>false))
      TestUser.send(:has_funnel)
    end
    it "should add the :unknown state" do
      TestUser.should_receive(:state).with(:unknown)
      TestUser.send(:has_funnel)
    end
    it "should initialize the other states" do
      TestUser.should_receive(:initialize_states)
      TestUser.send(:has_funnel)
    end
    describe "when creating funnel events" do
      it "should wrap the state_machine event method" do
        p = Proc.new {transitions :from, :to}
        TestUser.should_receive(:event).with(:funnel_test, p)
        TestUser.send(:funnel_event, :test, &p)
      end
    end
    it "should add the association for funnel visitors" do
      TestUser.should_receive(:has_many).with(:visitors, {:class_name=>"FunnelVisitor"})
      TestUser.send(:has_funnel, :visitor_class_name=>"FunnelVisitor")
    end
  end
  describe "for the FunnelVisitor class" do
    it "should add the acts_as_state_machine directive" do
      FunnelVisitor.should_receive(:acts_as_funnel_state_machine).with(hash_including(:log_transitions=>true, :validate_on_transitions=>false))
      TestUser.send(:has_funnel)
    end
    it "should add the :unknown state" do
      FunnelVisitor.should_receive(:state).with(:unknown)
      TestUser.send(:has_funnel)
    end    
    it "should initialize the other states" do
      FunnelVisitor.should_receive(:initialize_states)
      TestUser.send(:has_funnel)
    end
    it "should add the association for users" do
      FunnelVisitor.should_receive(:belongs_to).with(:user, :class_name=>"TestUser", :foreign_key=>:user_id)
      TestUser.send(:has_funnel, :visitor_class_name=>"FunnelVisitor")
    end
  end
end

describe "for instance methods on a acts_as_funnel model" do
  describe "when logging transitions" do
  end
end