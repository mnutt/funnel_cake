require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/../init'

describe "using acts_as_funnel on a FunnelEvent model" do
  class TestFunnelEvent
    include FunnelCake::ActsAsFunnelEvent::FunnelEventExtensions
  end
  
  before(:each) do
    TestFunnelEvent.stub!(:has_one)
  end
  it "should add the association for user" do
    TestFunnelEvent.should_receive(:has_one)
    TestFunnelEvent.send(:acts_as_funnel_event)
  end
  it "should set the default name of the User model" do
    TestFunnelEvent.should_receive(:has_one).with(:user, :class_name=>"User")
    TestFunnelEvent.send(:acts_as_funnel_event)
  end
  it "should use a user-supplied name for the User model" do
    TestFunnelEvent.should_receive(:has_one).with(:user, :class_name=>"UserOverride")
    TestFunnelEvent.send(:acts_as_funnel_event, :class_name=>"UserOverride")
  end
  
end

describe "for instance methods on a acts_as_funnel model" do
  
  
  
end