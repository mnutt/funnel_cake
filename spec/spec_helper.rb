require 'spec'
require 'active_support'

gem 'timecop'
require 'timecop'

gem 'mongo_mapper'
require 'mongo_mapper'

module EngineMacros
  def build_date(offset={})
    DateTime.civil(1978, 5, 12, 12, 0, 0, Rational(-5, 24)).advance(offset)
  end

  def create_visitor_with(args={}, &block)
    v = Factory.create :visitor, args
    yield v
    v.save
    v
  end

  def create_event_for(v, args={})
    v.events << Factory.create(:event, args)
  end
end

Spec::Runner.configure do |config|
  config.before(:each) do
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end
  config.include(EngineMacros)
end

ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'funnel_cake'))
ActiveSupport::Dependencies.load_paths.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'app', 'models'))

gem 'factory_girl'
require 'factory_girl'

class Rails
  def self.cache
    self
  end
  def self.fetch(a=nil, b=nil, &block)
    yield
  end
end

MongoMapper.connection = Mongo::Connection.new '127.0.0.1', 27017 #, :logger => Logger.new(STDOUT)
MongoMapper.database = 'funnelcake_test'

class User; end


Spec::Matchers.define :only_have_objects do |expected|
  match do |actual|
    actual.sort{|a,b| a._id.to_s<=>b._id.to_s} == expected.sort{|a,b| a._id.to_s<=>b._id.to_s}
  end
  failure_message_for_should do |actual|
    _expected = expected.collect(&:inspect).collect{|s| "   #{s}"}.join("\n")
    _actual = actual.collect(&:inspect).collect{|s| "   #{s}"}.join("\n")
    _expected = '   []' if expected.empty?
    _actual = '   []' if actual.empty?
    "expected to only have objects:\n#{_expected}\nbut got objects:\n#{_actual}"
  end
end
