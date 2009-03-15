
$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require "#{File.dirname(__FILE__)}/../init"


config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.configurations = config
ActiveRecord::Base.logger = nil #Logger.new(File.dirname(__FILE__) + "/../debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'mysql'])

load(File.dirname(__FILE__) + "/schema.rb") if File.exist?(File.dirname(__FILE__) + "/schema.rb")

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
end

require 'spec/interop/test'

module Spec
  module Rails

    module Example
      class RailsExampleGroup < Test::Unit::TestCase
        
        # Rails >= r8570 uses setup/teardown_fixtures explicitly
        # However, Rails >= r8664 extracted these out to use ActiveSupport::Callbacks.
        # The latter case is handled at the TestCase level, in interop/testcase.rb
        # unless ActiveSupport.const_defined?(:Callbacks) and self.include?(ActiveSupport::Callbacks)
          before(:each) do
            setup_fixtures if self.respond_to?(:setup_fixtures)
          end
          after(:each) do
            teardown_fixtures if self.respond_to?(:teardown_fixtures)
          end
        # end
        
        Spec::Example::ExampleGroupFactory.default(self)
        
      end
    end
  end
end
module Spec
  module Rails
    module Example
      # Model examples live in $RAILS_ROOT/spec/models/.
      #
      # Model examples use Spec::Rails::Example::ModelExampleGroup, which
      # provides support for fixtures and some custom expectations via extensions
      # to ActiveRecord::Base.
      class ModelExampleGroup < RailsExampleGroup
        Spec::Example::ExampleGroupFactory.register(:model, self)
      end
    end
  end
end
