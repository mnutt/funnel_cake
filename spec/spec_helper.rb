require 'spec'
require 'active_support'

gem 'mongo_mapper'
require 'mongo_mapper'

Spec::Runner.configure do |config|
  config.before(:each) do
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end
end

ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'funnel_cake'))
ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'app', 'models'))

module FunnelCake::UserStates
  def initialize_states
    funnel_state :page_visited, :primary=>true
    funnel_event :view_page do
      transitions :unknown,       :page_visited
      transitions :page_visited,  :page_visited
    end
    funnel_event :start_a do
      transitions :page_visited,  :a_started
    end
    funnel_event :start_b do
      transitions :a_started,     :b_started
    end
  end
end

class Rails
  def self.cache
    self
  end
  def self.fetch(a=nil, b=nil, &block)
    yield
  end
end

MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => Logger.new(STDOUT))
MongoMapper.database = 'funnelcake_test'

