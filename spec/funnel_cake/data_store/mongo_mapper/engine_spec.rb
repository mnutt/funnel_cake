require 'spec_helper'

class UserDummy; end

describe FunnelCake::DataStore::MongoMapper::Engine do
  before(:each) do
    FunnelCake.configure do
      data_store :mongo_mapper
      state :page_visited, :primary=>true
      event :view_page do
        transitions :from=>:unknown,       :to=>:page_visited
        transitions :from=>:page_visited,  :to=>:page_visited
      end
      event :start_a do
        transitions :from=>:page_visited,  :to=>:a_started
      end
      event :start_b do
        transitions :from=>:a_started,     :to=>:b_started
      end
    end    
    FunnelCake.run
  end

  describe 'when setting the engine classes' do
    it 'should use the defaults' do
      FunnelCake.engine.user_class.should == User
      FunnelCake.engine.visitor_class.should == Analytics::Visitor
      FunnelCake.engine.event_class.should == Analytics::Event
    end
    it 'should set custom classes' do
      FunnelCake.engine.user_class.should == User
      FunnelCake.engine.user_class = UserDummy
      FunnelCake.engine.user_class.should == UserDummy
    end
  end

  describe 'when finding visitors by eligibility to move from state' do
    describe 'without a date range' do  
      before(:each) do
        @a = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @b = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
        end
        @c = create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @d = create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted
        end
      end
      it 'should return visitors who entered the state MINUS those who exited the state' do
        FunnelCake.engine.eligible_to_move_from_state(:a_started).find.should only_have_objects([ @b ])
      end
      it 'should count visitors who entered the state MINUS those who exited the state' do
        FunnelCake.engine.eligible_to_move_from_state(:a_started).count.should == 1
      end
    end
    describe 'for a given date range' do
      before(:each) do
        @visitors = []
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-15), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'AAA') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-13), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'BBB') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'aaa'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'ccc'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>7), :referer=>'ddd'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted, :created_at=>build_date(:days=>-7), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-7), :referer=>'ddd'
        end
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should return the visitors who entered the state before the end MINUS those who exited before the start' do
        FunnelCake.engine.eligible_to_move_from_state(:a_started, @opts).find.should only_have_objects([ 
          @visitors[1], @visitors[2],
        ])
      end
      it 'should count the visitors who entered the state before the end MINUS those who exited before the start' do
        FunnelCake.engine.eligible_to_move_from_state(:a_started, @opts).count.should == 2
      end
      describe 'with a has_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :has_event_with=>{:referer=>'aaa'} )
            )
            @finder_b = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :has_event_with=>{:referer=>'bbb'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :has_event_with=>{:referer=>/a+/} )
            )
            @finder_b = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
      end
      describe 'with a first_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :first_event_with=>{:referer=>'aaa'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        # describe 'for a regex match' do
        #   before(:each) do
        #     @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
        #       @opts.merge( :first_event_with=>{:referer=>/a+/} )
        #     )
        #   end        
        #   it 'should return the visitors' do
        #     @finder_a.find.should only_have_objects([ @visitors[1] ])
        #   end
        #   it 'should count the visitors' do
        #     @finder_a.count.should == 1
        #   end
        # end
      end
      describe 'with a visitor_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :visitor_with=>{:ip=>'AAA'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.eligible_to_move_from_state(:a_started, 
              @opts.merge( :visitor_with=>{:ip=>/A+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
      end
      describe 'with an attrition period' do
        before(:each) do
          @finder = FunnelCake.engine.eligible_to_move_from_state(:a_started,
            @opts.merge( :attrition_period=>14.days )        
          )
        end
        it 'should return the visitors' do
          @finder.find.should only_have_objects([])
        end
        it 'should count the visitors' do
          @finder.count.should == 0
        end
      end
    end
  end

  describe 'when finding visitors by move to state' do
    describe 'without a date range' do  
      before(:each) do
        @a = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @b = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
        end
        @c = create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @d = create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted
        end
      end
      it 'should return visitors who entered the state' do
        FunnelCake.engine.moved_to_state(:a_started).find.should only_have_objects([ @a, @b ])
      end
      it 'should count visitors who entered the state' do
        FunnelCake.engine.moved_to_state(:a_started).count.should == 2
      end
    end
    describe 'for a given date range' do
      before(:each) do
        @visitors = []
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-15), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'AAA') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-13), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'BBB') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'aaa'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'ccc'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>7), :referer=>'ddd'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted, :created_at=>build_date(:days=>-7), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-7), :referer=>'ddd'
        end
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should return the visitors who entered the state during the date range' do
        FunnelCake.engine.moved_to_state(:b_started, @opts).find.should only_have_objects([ 
          @visitors[1], @visitors[6],
        ])
      end
      it 'should return the visitors who entered the state during the date range' do
        FunnelCake.engine.moved_to_state(:b_started, @opts).count.should == 2
      end
      describe 'with a has_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_to_state(:b_started, 
              @opts.merge( :has_event_with=>{:referer=>'aaa'} )
            )
            @finder_b = FunnelCake.engine.moved_to_state(:b_started, 
              @opts.merge( :has_event_with=>{:referer=>'bbb'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_to_state(:b_started, 
              @opts.merge( :has_event_with=>{:referer=>/a+/} )
            )
            @finder_b = FunnelCake.engine.moved_to_state(:b_started, 
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
      end
      describe 'with a first_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_to_state(:b_started,
              @opts.merge( :first_event_with=>{:referer=>'aaa'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end      
        # describe 'for a regex match' do
        #   before(:each) do
        #     @finder_a = FunnelCake.engine.moved_to_state(:b_started,
        #       @opts.merge( :first_event_with=>{:referer=>/a+/} )
        #     )
        #   end        
        #   it 'should return the visitors' do
        #     @finder_a.find.should only_have_objects([ @visitors[1] ])
        #   end
        #   it 'should count the visitors' do
        #     @finder_a.count.should == 1
        #   end
        # end      
      end
      describe 'with a visitor_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_to_state(:b_started,
              @opts.merge( :visitor_with=>{:ip=>'AAA'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_to_state(:b_started,
              @opts.merge( :visitor_with=>{:ip=>/A+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
      end
    end
  end

  describe 'when finding visitors by move from state' do
    describe 'without a date range' do  
      before(:each) do
        @a = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @b = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
        end
        @c = create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @d = create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted
        end
      end
      it 'should return visitors who entered the state' do
        FunnelCake.engine.moved_from_state(:a_started).find.should only_have_objects([ @a, @c ])
      end
      it 'should count visitors who entered the state' do
        FunnelCake.engine.moved_from_state(:a_started).count.should == 2
      end
    end
    describe 'for a given date range' do
      before(:each) do
        @visitors = []
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-15), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'AAA') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-13), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'BBB') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'aaa'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'ccc'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>7), :referer=>'ddd'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted, :created_at=>build_date(:days=>-7), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-7), :referer=>'ddd'
        end
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should return the visitors who exited the state during the date range' do
        FunnelCake.engine.moved_from_state(:a_started, @opts).find.should only_have_objects([ 
          @visitors[1], @visitors[6],
        ])
      end
      it 'should count the visitors who exited the state during the date range' do
        FunnelCake.engine.moved_from_state(:a_started, @opts).count.should == 2
      end
      describe 'with a has_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :has_event_with=>{:referer=>'aaa'} )
            )
            @finder_b = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :has_event_with=>{:referer=>'bbb'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end      
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
            @finder_b = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end      
      end
      describe 'with a first_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :first_event_with=>{:referer=>'aaa'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end  
        end      
        # describe 'for a regex match' do
        #   before(:each) do
        #     @finder_a = FunnelCake.engine.moved_from_state(:a_started,
        #       @opts.merge( :first_event_with=>{:referer=>/a+/} )
        #     )
        #   end
        #   it 'should return the visitors' do
        #     @finder_a.find.should only_have_objects([ @visitors[1] ])
        #   end  
        #   it 'should count the visitors' do
        #     @finder_a.count.should == 1
        #   end  
        # end      
      end
      describe 'with a visitor_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :visitor_with=>{:ip=>'AAA'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_from_state(:a_started,
              @opts.merge( :visitor_with=>{:ip=>/A+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
      end
    end
  end

  describe 'when finding visitors by move from state to state' do
    describe 'without a date range' do  
      before(:each) do
        @a = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @b = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
        end
        @c = create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @d = create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted
        end
      end
      it 'should return visitors who moved between states' do
        FunnelCake.engine.moved_between_states(:a_started, :b_started).find.should only_have_objects([ @a, @c ])
      end
      it 'should count visitors who moved between states' do
        FunnelCake.engine.moved_between_states(:a_started, :b_started).count.should == 2
      end
    end
    describe 'for a given date range' do
      before(:each) do
        @visitors = []
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-15), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'AAA') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-13), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'BBB') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'aaa'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'ccc'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>7), :referer=>'ddd'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted, :created_at=>build_date(:days=>-7), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-7), :referer=>'ddd'
        end
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should return the visitors who exited the start state and entered the end state during the date range' do
        FunnelCake.engine.moved_between_states(:a_started, :b_started, @opts).find.should only_have_objects([ 
          @visitors[1], @visitors[6],
        ])
      end
      it 'should count the visitors who exited the start state and entered the end state during the date range' do
        FunnelCake.engine.moved_between_states(:a_started, :b_started, @opts).count.should == 2
      end
      describe 'with states in between' do
        it 'should return the visitors who exited the start state and entered the end state during the date range' do
          @opts = { :date_range=>build_date(:days=>-31)..build_date(:days=>0) }
          FunnelCake.engine.moved_between_states(:page_visited, :b_started, @opts).find.should only_have_objects([ 
            @visitors[0], @visitors[1],
          ])
        end
        it 'should count the visitors who exited the start state and entered the end state during the date range' do
          @opts = { :date_range=>build_date(:days=>-31)..build_date(:days=>0) }
          FunnelCake.engine.moved_between_states(:page_visited, :b_started, @opts).count.should == 2
        end
      end
      describe 'with a has_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>'aaa'} )
            )
            @finder_b = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>'bbb'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>/a+/} )
            )
            @finder_b = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end      
      end
      describe 'with a first_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :first_event_with=>{:referer=>'aaa'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        # describe 'for a regex match' do
        #   before(:each) do
        #     @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
        #       @opts.merge( :first_event_with=>{:referer=>/a+/} )
        #     )
        #   end        
        #   it 'should return the visitors' do
        #     @finder_a.find.should only_have_objects([ @visitors[1] ])
        #   end
        #   it 'should count the visitors' do
        #     @finder_a.count.should == 1
        #   end
        # end
      end
      describe 'with a visitor_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :visitor_with=>{:ip=>'AAA'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_between_states(:a_started, :b_started,
              @opts.merge( :visitor_with=>{:ip=>/A+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
      end
    end
  end

  describe 'when finding visitors by move directly from state to state' do
    describe 'without a date range' do  
      before(:each) do
        @a = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @b = create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started
        end
        @c = create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started
        end
        @d = create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted
        end
      end
      it 'should return visitors who moved between states' do
        FunnelCake.engine.moved_directly_between_states(:a_started, :b_started).find.should only_have_objects([ @a, @c ])
      end
      it 'should count visitors who moved between states' do
        FunnelCake.engine.moved_directly_between_states(:a_started, :b_started).count.should == 2
      end
    end
    describe 'for a given date range' do
      before(:each) do
        @visitors = []
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-15), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'AAA') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'aaa'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-13), :referer=>'bbb'
        end
        @visitors << create_visitor_with(:ip=>'BBB') do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>-30), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'aaa'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:page_visited, :to=>:a_started, :created_at=>build_date(:days=>1), :referer=>'ccc'
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>7), :referer=>'ddd'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:unknown, :to=>:page_visted, :created_at=>build_date(:days=>-7), :referer=>'ccc'
        end
        @visitors << create_visitor_with do |v|
          create_event_for v, :from=>:a_started, :to=>:b_started, :created_at=>build_date(:days=>-7), :referer=>'ddd'
        end
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should return the visitors who exited the start state and entered the end state during the date range' do
        FunnelCake.engine.moved_directly_between_states(:a_started, :b_started, @opts).find.should only_have_objects([ 
          @visitors[1], @visitors[6],
        ])
      end
      it 'should count the visitors who exited the start state and entered the end state during the date range' do
        FunnelCake.engine.moved_directly_between_states(:a_started, :b_started, @opts).count.should == 2
      end
      describe 'with states in between' do
        it 'should return no visitors' do
          @opts = { :date_range=>build_date(:days=>-31)..build_date(:days=>0) }
          FunnelCake.engine.moved_directly_between_states(:page_visited, :b_started, @opts).find.should only_have_objects([])
        end
        it 'should count no visitors' do
          @opts = { :date_range=>build_date(:days=>-31)..build_date(:days=>0) }
          FunnelCake.engine.moved_directly_between_states(:page_visited, :b_started, @opts).count.should == 0
        end
      end
      describe 'with a has_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>'aaa'} )
            )
            @finder_b = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>'bbb'} )
            )
          end
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>/a+/} )
            )
            @finder_b = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :has_event_with=>{:referer=>/b+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
            @finder_b.find.should only_have_objects([ @visitors[1] ])          
          end  
          it 'should count the visitors' do
            @finder_a.count.should == 1
            @finder_b.count.should == 1
          end  
        end      
      end
      describe 'with a first_event_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :first_event_with=>{:referer=>'aaa'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        # describe 'for a regex match' do
        #   before(:each) do
        #     @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
        #       @opts.merge( :first_event_with=>{:referer=>/a+/} )
        #     )
        #   end        
        #   it 'should return the visitors' do
        #     @finder_a.find.should only_have_objects([ @visitors[1] ])
        #   end
        #   it 'should count the visitors' do
        #     @finder_a.count.should == 1
        #   end
        # end
      end
      describe 'with a visitor_with filter' do
        describe 'for an exact match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :visitor_with=>{:ip=>'AAA'} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end
        describe 'for a regex match' do
          before(:each) do
            @finder_a = FunnelCake.engine.moved_directly_between_states(:a_started, :b_started,
              @opts.merge( :visitor_with=>{:ip=>/A+/} )
            )
          end        
          it 'should return the visitors' do
            @finder_a.find.should only_have_objects([ @visitors[1] ])
          end
          it 'should count the visitors' do
            @finder_a.count.should == 1
          end
        end      
      end
    end
  end

  describe 'querying a conversion' do
    describe 'for visitors' do
      before(:each) do
        @start = mock(:start, :find=>[1, 2, 3, 4, 5, 6], :count=>6)
        @end = mock(:end, :find=>[1, 2, 3], :count=>3)
        FunnelCake.engine.stub!(:eligible_to_move_from_state).and_return(@start)
        FunnelCake.engine.stub!(:moved_to_state).and_return(@end)
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should query the visitors eligible to move' do
        FunnelCake.engine.should_receive(:eligible_to_move_from_state).with(:a_started, @opts).once.and_return(@start)
        FunnelCake.engine.conversion_visitors(:a_started, :b_started, @opts)
      end
      it 'should query the visitors who moved' do
        FunnelCake.engine.should_receive(:moved_to_state).with(:b_started, @opts).once.and_return(@end)
        FunnelCake.engine.conversion_visitors(:a_started, :b_started, @opts)
      end
      it 'should return the list of converted visitors' do
        FunnelCake.engine.conversion_visitors(:a_started, :b_started, @opts).should == {
          :start=>[1, 2, 3, 4, 5, 6],
          :end=>[1, 2, 3],
        }
      end
    end
    describe 'for stats' do
      before(:each) do
        @start = mock(:start, :find=>[1, 2, 3, 4, 5, 6], :count=>6)
        @end = mock(:end, :find=>[1, 2, 3], :count=>3)
        FunnelCake.engine.stub!(:eligible_to_move_from_state).and_return(@start)
        FunnelCake.engine.stub!(:moved_to_state).and_return(@end)
        @date_range = build_date(:days=>-14)..build_date(:days=>0)
        @opts = { :date_range=>@date_range }
      end
      it 'should query the visitors eligible to move' do
        FunnelCake.engine.should_receive(:eligible_to_move_from_state).with(:a_started, @opts).once.and_return(@start)
        FunnelCake.engine.conversion_stats(:a_started, :b_started, @opts)
      end
      it 'should query the visitors who moved' do
        FunnelCake.engine.should_receive(:moved_to_state).with(:b_started, @opts).once.and_return(@end)
        FunnelCake.engine.conversion_stats(:a_started, :b_started, @opts)
      end
      it 'should return the stats' do
        FunnelCake.engine.conversion_stats(:a_started, :b_started, @opts).should == FunnelCake::DataHash[{
          :start=>6,
          :end=>3,
          :rate=>0.5,        
        }]
      end
    end  
    describe 'rate only' do  
      it 'should return the rate' do
        FunnelCake.engine.should_receive(:conversion_stats).with(:a_started, :b_started, @opts).once.and_return({
          :start=>6,
          :end=>3,
          :rate=>0.5,        
        })      
        FunnelCake.engine.conversion_rate(:a_started, :b_started, @opts).should == 0.5
      end
    end
    describe 'for history over a period of time' do
      describe 'for a 2 week window' do
        describe 'with the default history length' do
          before(:each) do
            @current_date = DateTime.civil(1978, 1, 15, 12, 0, 0, Rational(-5, 24))
            Timecop.freeze(@current_date)                    
            @opts = {
              :time_period=>2.weeks,
            }
            @data = FunnelCake::DataHash[{:start=>6, :end=>3, :rate=>0.5}]
            FunnelCake.engine.stub!(:conversion_stats).and_return(@data)
          end
          after(:each) { Timecop.return }
          it 'should return the right number of stats' do
            FunnelCake.engine.conversion_history(:a_started, :b_started, @opts).values.length.should == 8
          end
          it 'should query the right dates' do
            period_end = DateTime.civil(1978, 1, 29, 12, 0, 0, Rational(-5, 24)).to_date
            0.upto(7) do |i|
              topts = @opts.merge(:date_range=>period_end.advance(:weeks=>(-1-i)*2)...period_end.advance(:weeks=>-i*2), :attrition_period=>2.weeks)
              FunnelCake.engine.should_receive(:conversion_stats).with(:a_started, :b_started, topts).and_return(@data)
            end
            FunnelCake.engine.conversion_history(:a_started, :b_started, @opts)
          end
        end
        describe 'with a custom history length' do
          before(:each) do
            DateTime.stub!(:now).and_return(build_date(:days=>0))
            @opts = { :time_period=>2.weeks, :max_history=>3 }
            FunnelCake.engine.stub!(:conversion_stats).and_return(FunnelCake::DataHash[{:start=>6, :end=>3, :rate=>0.5}])
          end
          it 'should return the right number of stats' do
            FunnelCake.engine.conversion_history(:a_started, :b_started, @opts).values.length.should == 6
          end
        end
      end
    end
  end

end