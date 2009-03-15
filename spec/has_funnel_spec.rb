require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/../init'


describe "using has_funnel on a User model" do
  class TestUser
    include FunnelCake::HasFunnel::UserExtensions
  end

  before(:each) do
    TestUser.stub!(:acts_as_funnel_state_machine)
    TestUser.stub!(:has_many)
    TestUser.stub!(:state)
  end
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

  describe "when creating funnel events" do
    it "should wrap the state_machine event method" do
      p = Proc.new {transitions :from, :to}
      TestUser.should_receive(:event).with(:funnel_test, p)
      TestUser.send(:funnel_event, :test, &p)
    end
  end
end

describe "for instance methods on a acts_as_funnel model" do
  describe "when logging transitions" do
  end
end