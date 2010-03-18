module FunnelCake

  # Configuration class, defines a simple DSL for setting up FunnelCake
  class Config
    def initialize(opts={})
      @enabled = true
      @user_class = User if Object.const_defined?('User')
      @visitor_class = Analytics::Visitor
      @event_class = Analytics::Event
      @ignore_class = Analytics::Ignore
      @data_store = :mongo_mapper
      @engine = FunnelCake::Engine
      @states = { :unknown=>{} }
      @events = {}
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

      def user_class(klass); @config.user_class = class_from(klass); end
      def visitor_class(klass); @config.visitor_class = class_from(klass); end
      def event_class(klass); @config.event_class = class_from(klass); end
      def ignore_class(klass); @config.ignore_class = class_from(klass); end

      def data_store(store); @config.data_store = store; end

      def state(name, opts={}); @config.states[name] = opts; end
      def event(name, opts={}, &block)
        @config.events[name] = opts.merge(:block=>block)
      end

      private

      def class_from(constant_or_string)
        if constant_or_string.is_a?(String)
          constant_or_string.constantize
        else
          constant_or_string
        end
      end
    end
  end

  class << self
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
      initialize_datastore_hooks!
      initialize_state_machine!
    end

    # Resets the configuration object, useful for tests
    def reset_configuration
      @@configuration = Config.new
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
      @@configuration.visitor_class.send :extend, FunnelCake::ActsAsFunnelStateMachine::ActMacro
      @@configuration.visitor_class.acts_as_funnel_state_machine({
        :initial=>:unknown, :validate_on_transitions=>false,
        :log_transitions=>true, :error_on_invalid_transition=>false
      })
      @@configuration.states.each do |name, opts|
        @@configuration.visitor_class.funnel_state name, opts
      end
      @@configuration.events.each do |name, opts|
        event_opts = opts.clone
        block = event_opts.delete(:block)
        @@configuration.visitor_class.funnel_event name, event_opts, &block
      end
    end

    def initialize_datastore_hooks!
      datastore_module = "FunnelCake::DataStore::#{@@configuration.data_store.to_s.classify}"
      @@configuration.event_class.class_eval do
        include "#{datastore_module}::Event".constantize
      end
      @@configuration.ignore_class.class_eval do
        include "#{datastore_module}::Ignore".constantize
      end
      @@configuration.visitor_class.class_eval do
        include "#{datastore_module}::Visitor".constantize
      end
      @@configuration.engine = "#{datastore_module}::Engine".constantize
      @@configuration.engine.user_class = @@configuration.user_class
      @@configuration.engine.visitor_class = @@configuration.visitor_class
      @@configuration.engine.event_class = @@configuration.event_class
    end

  end

end
