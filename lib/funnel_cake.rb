require 'rails'

module FunnelCake

  autoload :HasFunnel, 'funnel_cake/has_funnel/user_extensions'
  autoload :ActsAsFunnelStateMachine, 'funnel_cake/acts_as_funnel_state_machine'
  autoload :DataStore, 'funnel_cake/data_store/mongo_mapper/engine'
  autoload :DataHash, 'funnel_cake/data_hash'

  class RailsEngine < Rails::Engine
    rake_tasks do
      load File.join(File.dirname(__FILE__), '../tasks/funnel_cake_tasks.rake')
    end

    config.autoload_once_paths << "#{root}/app/models"

    initializer "static assets" do |app|
      app.middleware.insert_after ActionDispatch::Static, ActionDispatch::Static, "#{root}/public"
    end

    initializer "disable autoload" do |app|
      ActiveSupport::Dependencies.autoloaded_constants.reject! {|mod| mod == "Analytics" }
    end
  end

  # Configuration class, defines a simple DSL for setting up FunnelCake
  class Config
    def initialize(opts={})
      @enabled = true
      @user_class = 'User'
      @visitor_class = 'Analytics::Visitor'
      @event_class = 'Analytics::Event'
      @ignore_class = 'Analytics::Ignore'
      @data_store = :mongo_mapper
      require 'funnel_cake/engine'
      @engine = FunnelCake::Engine
      @states = ActiveSupport::OrderedHash.new.merge({ :unknown=>{} })
      @events = ActiveSupport::OrderedHash.new
    end

    # Configuration Accessors
    attr_accessor :enabled
    def enabled?; @enabled; end
    attr_accessor :user_class, :visitor_class, :event_class, :ignore_class
    attr_accessor :data_store
    attr_accessor :states, :events
    attr_accessor :engine

    # DSL Methods
    class DSL
      def initialize(parent)
        @config = parent
      end

      def enable; @config.enabled = true; end
      def disable; @config.enabled = false; end

      def user_class(klass); @config.user_class = klass.to_s; end
      def visitor_class(klass); @config.visitor_class = klass.to_s; end
      def event_class(klass); @config.event_class = klass.to_s; end
      def ignore_class(klass); @config.ignore_class = klass.to_s; end

      def data_store(store); @config.data_store = store; end

      def state(name, opts={}); @config.states[name] = opts; end
      def event(name, opts={}, &block)
        @config.events[name] = opts.merge(:block=>block)
      end
    end
  end

  class << self
    @@configuration ||= nil

    # Accessors for FunnelCake's configuration settings
    def configuration; @@configuration; end
    def configuration=(config); @@configuration = config; end

    # Configuration constructor, takes a block that implements the
    # config DSL in FunnelCake::Config... looks like:
    #
    # FunnelCake.configure do
    #   enable
    #   user_class 'MyUserClass'
    #   state :converted, :primary=>true
    #   event :convert do
    #     transitions :from=>:unknown, :to=>:converted
    #   end
    # end
    def configure(&block)
      @@configuration ||= Config.new
      configuration_dsl = Config::DSL.new(@@configuration)
      configuration_dsl.instance_eval(&block)
    end

    # Resets the configuration object, useful for tests
    def reset_configuration
      @@configuration = Config.new
    end

    # Initializes the FunnelCake library, and applies the configuration settings
    def run
      return unless enabled?
      initialize_datastore_hooks!
      initialize_state_machine!
    end

    # Delegate missed methods to the configuration object,
    # so we can do simple things like FunnelCake.enabled
    def method_missing(method, *params)
      if configuration.respond_to?(method)
        configuration.send(method, *params)
      else
        super
      end
    end

    private

    def initialize_state_machine!
      @@configuration.visitor_class.constantize.send :extend, FunnelCake::ActsAsFunnelStateMachine::ActMacro
      @@configuration.visitor_class.constantize.acts_as_funnel_state_machine({
        :initial=>:unknown, :validate_on_transitions=>false,
        :log_transitions=>true, :error_on_invalid_transition=>false
      })
      @@configuration.states.each do |name, opts|
        @@configuration.visitor_class.constantize.funnel_state name, opts
      end
      @@configuration.events.each do |name, opts|
        event_opts = opts.clone
        block = event_opts.delete(:block)
        @@configuration.visitor_class.constantize.funnel_event name, event_opts, &block
      end
    end

    def initialize_datastore_hooks!
      datastore_module = "FunnelCake::DataStore::#{@@configuration.data_store.to_s.classify}"
      @@configuration.event_class.constantize.class_eval do
        include "#{datastore_module}::Event".constantize
      end
      @@configuration.ignore_class.constantize.class_eval do
        include "#{datastore_module}::Ignore".constantize
      end
      @@configuration.visitor_class.constantize.class_eval do
        include "#{datastore_module}::Visitor".constantize
      end
      @@configuration.engine = "#{datastore_module}::Engine".constantize
      @@configuration.engine.user_class = @@configuration.user_class.constantize
      @@configuration.engine.visitor_class = @@configuration.visitor_class.constantize
      @@configuration.engine.event_class = @@configuration.event_class.constantize
    end

  end

end
