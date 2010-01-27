$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'
require 'active_record/fixtures'
require 'action_controller'
# require "#{File.dirname(__FILE__)}/../rails/init"


config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.configurations = config
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/../log/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'mysql'])

load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")

class ActiveSupport::TestCase #:nodoc:
  superclass_delegating_accessor :fixture_path
  superclass_delegating_accessor :use_transactional_fixtures
  superclass_delegating_accessor :use_instantiated_fixtures  
end
ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActiveSupport::TestCase.fixture_path)

class ActiveSupport::TestCase #:nodoc:
  include ActiveRecord::TestFixtures
  
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end

require 'spec/interop/test'


module Test
  module Unit
    class TestCase
      # Edge rails (r8664) introduces class-wide setup & teardown callbacks for Test::Unit::TestCase.
      # Make sure these still get run when running TestCases under rspec:
      prepend_before(:each) do
        run_callbacks :setup if respond_to?(:run_callbacks)
      end
      append_after(:each) do
        run_callbacks :teardown if respond_to?(:run_callbacks)
      end
    end
  end
end

require 'spec/example/model_example_group'
require 'spec/example/render_observer'
require 'spec/example/functional_example_group'
require 'spec/example/controller_example_group'

