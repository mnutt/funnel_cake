require 'spec_helper'

describe FunnelCake::Config do
  describe 'when configuring funnelcake' do
    class FunnelCakeConfigDummy
      def self.before_create(*args); end
      def self.after_create(*args); end      
    end
    
    it 'should construct the configuration class' do
      @config = FunnelCake::Config.new
      FunnelCake::Config.should_receive(:new).and_return(@config)
      FunnelCake.configure {}
      FunnelCake.configuration.should == @config
    end
    describe 'with the config DSL' do
      it 'should enable' do
        FunnelCake.configure { enable }
        FunnelCake.configuration.enabled.should be_true
        FunnelCake.configuration.enabled?.should be_true        
      end
      it 'should disable' do
        FunnelCake.configure { disable }
        FunnelCake.configuration.enabled.should be_false
        FunnelCake.configuration.enabled?.should be_false        
      end
      it 'should set the user class as a string' do
        FunnelCake.configure { user_class 'FunnelCakeConfigDummy' }
        FunnelCake.configuration.user_class.should == FunnelCakeConfigDummy
      end
      it 'should set the user class as a constant' do
        FunnelCake.configure { user_class FunnelCakeConfigDummy }
        FunnelCake.configuration.user_class.should == FunnelCakeConfigDummy
      end
      it 'should set the visitor class as a constant' do
        FunnelCake.configure { visitor_class FunnelCakeConfigDummy }
        FunnelCake.configuration.visitor_class.should == FunnelCakeConfigDummy
      end
      it 'should set the event class as a constant' do
        FunnelCake.configure { event_class FunnelCakeConfigDummy }
        FunnelCake.configuration.event_class.should == FunnelCakeConfigDummy
      end
      it 'should set the ignore class as a constant' do
        FunnelCake.configure { ignore_class FunnelCakeConfigDummy }
        FunnelCake.configuration.ignore_class.should == FunnelCakeConfigDummy
      end
      it 'should set the data_store' do
        module FunnelCake::DataStore::MyCustomDatastore; end
        module FunnelCake::DataStore::MyCustomDatastore::Event; end
        module FunnelCake::DataStore::MyCustomDatastore::Visitor; end
        module FunnelCake::DataStore::MyCustomDatastore::Ignore; end
        FunnelCake.configure { data_store :my_custom_datastore }
        FunnelCake.configuration.data_store.should == :my_custom_datastore
      end
      describe 'when configuring then funnel' do
        it 'should set the states' do
          FunnelCake.configure do 
            state :completed_a
            state :completed_b, :some=>:option
          end
          FunnelCake.configuration.states.should == {
            :unknown=>{},
            :completed_a=>{},
            :completed_b=>{:some=>:option}
          }
        end
        it 'should set the events' do
          FunnelCake.configure do 
            event :complete_a do
              transitions :from=>:unknown, :to=>:completed_a
            end
            event :complete_b, :some=>:option do
              transitions :from=>:completed_a, :to=>:completed_b
            end
          end
          FunnelCake.configuration.events[:complete_a][:block].should_not be_nil
          FunnelCake.configuration.events[:complete_b][:some].should == :option
          FunnelCake.configuration.events[:complete_b][:block].should_not be_nil          
        end
      end
    end
    describe 'by default' do
      it 'should be enabled' do
        FunnelCake.configure {}
        FunnelCake.configuration.enabled?.should be_true
      end
      it 'should set the user class' do
        FunnelCake.configure {}
        FunnelCake.configuration.user_class.should == nil # User isn't defined yet
      end
      it 'should set the visitor class' do
        FunnelCake.configure {}
        FunnelCake.configuration.visitor_class.should == Analytics::Visitor
      end
      it 'should set the event class' do
        FunnelCake.configure {}
        FunnelCake.configuration.event_class.should == Analytics::Event
      end
      it 'should set the ignore class' do
        FunnelCake.configure {}
        FunnelCake.configuration.ignore_class.should == Analytics::Ignore
      end
      it 'should set the datastore' do
        FunnelCake.configure {}
        FunnelCake.configuration.data_store.should == :mongo_mapper
      end
      it 'should set the states' do
        FunnelCake.configure {}
        FunnelCake.configuration.states.should == { :unknown=>{} }
      end
      it 'should set the events' do
        FunnelCake.configure {}
        FunnelCake.configuration.events.should == {}
      end
    end
    describe 'when applying the configuration settings' do
      it 'should set the engine classes' do
        FunnelCake::Engine.should_receive(:user_class=).with(FunnelCakeConfigDummy)
        FunnelCake::Engine.should_receive(:visitor_class=).with(FunnelCakeConfigDummy)      
        FunnelCake::Engine.should_receive(:event_class=).with(FunnelCakeConfigDummy)      
        FunnelCake.configure do
          user_class    FunnelCakeConfigDummy
          visitor_class FunnelCakeConfigDummy
          event_class   FunnelCakeConfigDummy                    
        end
      end
      describe 'when initializing the funnel state machine' do
        it 'should initialize the states' do
          FunnelCake.configure do
            visitor_class FunnelCakeConfigDummy
            state :state_a
            state :state_b, :some=>:option
          end
          FunnelCakeConfigDummy.states.size.should == 3
          FunnelCakeConfigDummy.states.include?(:unknown).should be_true
          FunnelCakeConfigDummy.states.include?(:state_a).should be_true
          FunnelCakeConfigDummy.states.include?(:state_b).should be_true          
          FunnelCakeConfigDummy.state_options(:state_b).should == {:some=>:option}
        end
        it 'should initialize the events' do
          block_dummy = lambda { puts 'dummy lambda' }
          FunnelCake.configure do
            visitor_class FunnelCakeConfigDummy
            event :event_a do
              transitions :from=>:a, :to=>:b
            end
            event :event_b, :some=>:option do
              transitions :from=>:b, :to=>:c
            end              
          end
          FunnelCakeConfigDummy.state_events_table.should == {
            :unknown=>[],
            :a=>[:event_a], 
            :b=>[:event_b], 
            :c=>[],
          }
        end
      end
      describe 'when initializing the datastore hooks' do
        describe 'for mongo_mapper' do
          before(:each) do
            FunnelCakeConfigDummy.stub!(:include)
          end
          it 'should mixin the event module' do
            FunnelCakeConfigDummy.should_receive(:include).with(FunnelCake::DataStore::MongoMapper::Event)
            FunnelCake.configure do
              data_store :mongo_mapper
              event_class FunnelCakeConfigDummy              
            end
          end
          it 'should mixin the ignore module' do
            FunnelCakeConfigDummy.should_receive(:include).with(FunnelCake::DataStore::MongoMapper::Ignore)            
            FunnelCake.configure do
              data_store :mongo_mapper
              ignore_class FunnelCakeConfigDummy              
            end
          end
          it 'should mixin the visitor module' do
            FunnelCakeConfigDummy.should_receive(:include).with(FunnelCake::DataStore::MongoMapper::Visitor)            
            FunnelCake.configure do
              data_store :mongo_mapper
              visitor_class FunnelCakeConfigDummy
            end
          end
        end
      end
    end
  end
  describe 'when querying the configuration' do
    it 'should delegate to the configuration object' do
      @config = FunnelCake::Config.new
      @config.enabled = 'dummy'
      FunnelCake::Config.should_receive(:new).and_return(@config)
      FunnelCake.configure {}
      FunnelCake.enabled.should == 'dummy'
    end
  end
end
