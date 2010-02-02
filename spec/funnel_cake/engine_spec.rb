require 'spec_helper'
# require 'spec_models'

describe "when querying funnel events", :type=>:model do
  describe "for a given date range" do
    before(:each) do
      start_date = DateTime.civil(1978, 5, 12, 12, 0, 0, Rational(-5, 24))
      end_date = DateTime.civil(1978, 5, 12, 17, 0, 0, Rational(-5, 24))
      @date_range = start_date..end_date
      FunnelCake::Engine.user_class_name = 'UserDummy'
      FunnelCake::Engine.visitor_class_name = 'Analytics::Visitor'
      FunnelCake::Engine.event_class_name = 'Analytics::Event'
    end

    describe "when calculating conversion rates" do
      describe "from state A to state B" do
        it "should be the correct rate" do
          @rate = FunnelCake::Engine.conversion_rate(:a_started, :b_started, {:date_range=>@date_range})
          @rate.should == (1.0/3.0)
        end
      end
    end
  end # for a given date range
end

describe "when finding users by funnel events", :type=>:model do
  it "should have 18 users" do
    UserDummy.count.should == 18
  end

  it "should have the correct number of funnel events for :before_before" do
    users(:before_before).funnelcake_events.count.should == 3
  end

  describe "for a given date range" do
    before(:each) do
      start_date = DateTime.civil(1978, 5, 12, 12, 0, 0, Rational(-5, 24))
      end_date = DateTime.civil(1978, 5, 12, 17, 0, 0, Rational(-5, 24))
      @date_range = start_date..end_date
      FunnelCake::Engine.user_class_name = 'UserDummy'
      FunnelCake::Engine.visitor_class_name = 'Analytics::Visitor'
      FunnelCake::Engine.event_class_name = 'Analytics::Event'
    end
    describe "by starting state A" do
      before(:each) do
        @found = FunnelCake::Engine.find_by_starting_state(:a_started, {:date_range=>@date_range})
      end
      it "should find the right number of users" do
        @found.count.should == 18
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
        @found.include?(users(:visitor_before_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_before_during)).should be_true
      end
      it "should find the :before_after user" do
        @found.include?(users(:before_after)).should be_true
        @found.include?(users(:visitor_before_after)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_before_after)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
        @found.include?(users(:visitor_during_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during_during)).should be_true
      end
      it "should find the :during_after user" do
        @found.include?(users(:during_after)).should be_true
        @found.include?(users(:visitor_during_after)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during_after)).should be_true
      end
      it "should find the :before user" do
        @found.include?(users(:before)).should be_true
        @found.include?(users(:visitor_before)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_before)).should be_true
      end
      it "should find the :during user" do
        @found.include?(users(:during)).should be_true
        @found.include?(users(:visitor_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during)).should be_true
      end
    end

    describe "by starting state A and ending state B" do
      before(:each) do
        @found = FunnelCake::Engine.find_by_state_pair(:a_started, :b_started, {:date_range=>@date_range})
      end
      it "should find the right number users" do
        @found.count.should == 6
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
        @found.include?(users(:visitor_before_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_before_during)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
        @found.include?(users(:visitor_during_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during_during)).should be_true
      end
    end

    describe "by starting state unknown and ending state B" do
      before(:each) do
        @found = FunnelCake::Engine.find_by_state_pair(:unknown, :b_started, {:date_range=>@date_range})
      end
      it "should find the right number users" do
        @found.count.should == 3
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
        @found.include?(users(:visitor_during_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during_during)).should be_true
      end
    end

    describe "by transition from state A to ending state B" do
      before(:each) do
        @found = FunnelCake::Engine.find_by_transition(:a_started, :b_started, {:date_range=>@date_range})
      end
      it "should find the right number users" do
        @found.count.should == 6
      end
      it "should find the :before_during user" do
        @found.include?(users(:before_during)).should be_true
        @found.include?(users(:visitor_before_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_before_during)).should be_true
      end
      it "should find the :during_during user" do
        @found.include?(users(:during_during)).should be_true
        @found.include?(users(:visitor_during_during)).should be_true
        @found.include?(funnelcake_visitors(:visitor_only_during_during)).should be_true
      end
    end

    describe "by transition unknown to ending state B" do
      before(:each) do
        @found = FunnelCake::Engine.find_by_transition(:unknown, :b_started, {:date_range=>@date_range})
      end
      it "should find the right number users" do
        @found.count.should == 0
      end
    end

  end # for a given date range

  describe "by transition from unknown to ending state B" do
    before(:each) do
      @found = FunnelCake::Engine.find_by_transition(:unknown, :b_started)
    end
    it "should find the right number users" do
      @found.count.should == 0
    end
  end

  describe "by starting state unknown and ending state B" do
    before(:each) do
      @found = FunnelCake::Engine.find_by_state_pair(:unknown, :b_started)
    end
    it "should find the right number of users" do
      @found.count.should == 18
    end
  end

end

