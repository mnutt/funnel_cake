require File.dirname(__FILE__) + '/spec_helper'
# require File.dirname(__FILE__) + '/../init'

class UserAssociationTest < ActiveRecord::Base
  set_table_name :users
  has_funnel :class_name=>'FunnelEventAssociationTest', :foreign_key=>'user_id'
  state :page_visited, :primary=>true
  funnel_event :view_page do
    transitions :unknown,                     :page_visited
    transitions :page_visited,                :page_visited
  end
  funnel_event :start_a do
    transitions :page_visited,                :a_started
  end    
  funnel_event :start_b do
    transitions :a_started,                :b_started
  end    
end

class FunnelEventAssociationTest < ActiveRecord::Base
  set_table_name :funnel_events
  acts_as_funnel_event :class_name=>'UserAssociationTest'
end

describe "when finding users by funnel events", :type=>:model do
  set_fixture_class :users => UserAssociationTest
  set_fixture_class :funnel_events => FunnelEventAssociationTest
  fixtures :users
  fixtures :funnel_events  
  
  it "should have 6 users" do
    UserAssociationTest.count.should == 9
  end

  it "should have 3 funnel events for :before_before" do
    users(:before_before).funnel_events.count.should == 3
  end
  
  describe "for a given date range" do
    before(:each) do
      start_date = DateTime.civil(1978, 5, 12, 12, 0, 0, Rational(-5, 24))
      end_date = DateTime.civil(1978, 5, 12, 17, 0, 0, Rational(-5, 24))
      @date_range = start_date..end_date
    end
    describe "by starting state A" do
      before(:each) do
        @found = UserAssociationTest.find_by_starting_state(:a_started, {:date_range=>@date_range})        
      end
      it "should find 6 users" do
        @found.count.should == 6
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
      end
      it "should find the :before_after user" do
        @found.include?(users(:before_after)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
      end
      it "should find the :during_after user" do
        @found.include?(users(:during_after)).should be_true
      end
      it "should find the :before user" do
        @found.include?(users(:before)).should be_true
      end
      it "should find the :during user" do
        @found.include?(users(:during)).should be_true
      end
    end
    
    describe "by starting state A and ending state B" do
      before(:each) do
        @found = UserAssociationTest.find_by_state_pair(:a_started, :b_started, {:date_range=>@date_range})        
      end
      it "should find 2 users" do
        @found.count.should == 2
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
      end
    end
    
    describe "by starting state unknown and ending state B" do
      before(:each) do
        @found = UserAssociationTest.find_by_state_pair(:unknown, :b_started, {:date_range=>@date_range})        
      end
      it "should find 2 users" do
        @found.count.should == 1
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
      end
    end    

    describe "by transition from state A to ending state B" do
      before(:each) do
        @found = UserAssociationTest.find_by_transition(:a_started, :b_started, {:date_range=>@date_range})        
      end
      it "should find 2 users" do
        @found.count.should == 2
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
      end
    end
    
    describe "by transition unknown to ending state B" do
      before(:each) do
        @found = UserAssociationTest.find_by_transition(:unknown, :b_started, {:date_range=>@date_range})        
      end
      it "should find 2 users" do
        @found.count.should == 0
      end
    end        

    describe "when calculating conversion rates" do
      describe "from state A to state B" do
        it "should be the correct rate" do
          @rate = UserAssociationTest.conversion_rate(:a_started, :b_started, {:date_range=>@date_range})        
          @rate.should == (2.0/3.0)
        end
      end    
    end
  
  end # for a given date range

  describe "by transition from unknown to ending state B" do
    before(:each) do
      @found = UserAssociationTest.find_by_transition(:unknown, :b_started)        
    end
    it "should find 2 users" do
      @found.count.should == 0
    end
  end        

  describe "by starting state unknown and ending state B" do
    before(:each) do
      @found = UserAssociationTest.find_by_state_pair(:unknown, :b_started)        
    end
    it "should find 2 users" do
      @found.count.should == 6
    end
  end      
  
end

