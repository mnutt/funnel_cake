# This code originally from Scott Baron's plugin: acts_as_state_machine
# Git fork:  git://github.com/jkrall/acts_as_state_machine.git

module FunnelCake                   #:nodoc:
  module ActsAsFunnelStateMachine        #:nodoc:
    class InvalidState < Exception #:nodoc:
    end
    class NoInitialState < Exception #:nodoc:
    end

    def self.included(base)        #:nodoc:
      base.extend ActMacro
    end

    module SupportingClasses
      class State
        attr_reader :name, :opts

        def initialize(name, opts)
          @name, @opts = name, opts
        end

        def entering(record)
          enteract = @opts[:enter]
          record.send(:run_transition_action, enteract) if enteract
        end

        def entered(record)
          afteractions = @opts[:after]
          return unless afteractions
          Array(afteractions).each do |afteract|
            record.send(:run_transition_action, afteract)
          end
        end

        def exited(record)
          exitact  = @opts[:exit]
          record.send(:run_transition_action, exitact) if exitact
        end

        def primary?
            @opts[:primary] == true
        end
        def hidden?
          @opts[:hidden] == true
        end
      end

      class StateTransition
        attr_reader :from, :to, :opts

        def initialize(opts)
          @from, @to, @event, @guard = opts[:from], opts[:to], opts[:event], opts[:guard]
          @opts = opts
        end

        def guard(obj)
          @guard ? obj.send(:run_transition_action, @guard) : true
        end

        def perform(record, data={})
          valid = true
          valid = record.valid? if record.class.read_inheritable_attribute(:validate_on_transitions)
          transition_valid = guard(record)
          return false unless transition_valid && valid
          loopback = record.current_state == to
          states = record.class.read_inheritable_attribute(:states)
          next_state = states[to]
          old_state = states[record.current_state]

          next_state.entering(record) unless loopback

          record.update_attributes({record.class.state_column => to.to_s})
          if record.class.read_inheritable_attribute(:log_transitions)
            record.send(record.class.read_inheritable_attribute(:transitions_logger), @from, @to, @event, data, opts)
          end

          next_state.entered(record) unless loopback
          old_state.exited(record) unless loopback
          true
        end


        def ==(obj)
          @from == obj.from && @to == obj.to
        end
      end

      class Event
        attr_reader :name
        attr_reader :transitions
        attr_reader :opts

        def initialize(name, opts, transition_table, state_events_table, parent, &block)
          @parent = parent
          @name = name.to_sym
          @transitions = transition_table[@name] = []
          instance_eval(&block) if block
          @transitions.each do |tr|
            state_events_table[tr.from] << @name
          end
          @opts = opts
          @opts.freeze
          @transitions.freeze
          freeze
        end

        def next_states(record)
          @transitions.select { |t| t.from == record.current_state }
        end

        def fire(record, data={})
          result = next_states(record).each do |transition|
            break true if transition.perform(record, data)
          end
          raise ActiveRecord::RecordInvalid.new(record) unless result == true
          true
        end

        def transitions(from, to, trans_opts={})
          @parent.funnel_state(from) unless @parent.states.include?(from)
          @parent.funnel_state(to) unless @parent.states.include?(to)
          trans_opts[:from] = from
          trans_opts[:to] = to
          Array(trans_opts[:from]).each do |s|
            @transitions << SupportingClasses::StateTransition.new(trans_opts.merge({:from => s.to_sym, :event => @name}))
          end
        end
      end
    end

    module ActMacro
      # Configuration options are
      #
      # * +column+ - specifies the column name to use for keeping the state (default: state)
      # * +initial+ - specifies an initial state for newly created objects (required)
      def acts_as_funnel_state_machine(opts)
        self.extend(ClassMethods)
        raise NoInitialState unless opts[:initial]

        write_inheritable_attribute :states, {}
        write_inheritable_attribute :primary_states, []
        write_inheritable_attribute :hidden_states, []
        write_inheritable_attribute :state_events_table, {}
        write_inheritable_attribute :initial_state, opts[:initial]
        write_inheritable_attribute :transition_table, {}
        write_inheritable_attribute :event_table, {}
        write_inheritable_attribute :state_column, opts[:column] || 'state'
        write_inheritable_attribute :log_transitions, opts[:log_transitions] || false
        write_inheritable_attribute :transitions_logger, opts[:transitions_logger] || :log_transition
        write_inheritable_attribute :validate_on_transitions, opts[:validate_on_transitions] || false

        class_inheritable_reader    :initial_state
        class_inheritable_reader    :state_column
        class_inheritable_reader    :transition_table
        class_inheritable_reader    :event_table
        class_inheritable_reader    :state_events_table

        self.send(:include, FunnelCake::ActsAsFunnelStateMachine::InstanceMethods)

        before_create               :set_initial_state
        after_create                :run_initial_state_actions
      end
    end

    module InstanceMethods
      def set_initial_state #:nodoc:
        write_attribute self.class.state_column, self.class.initial_state.to_s
        end

      def run_initial_state_actions
        initial = self.class.read_inheritable_attribute(:states)[self.class.initial_state.to_sym]
        initial.entering(self)
        initial.entered(self)
      end

      # Returns the current state the object is in, as a Ruby symbol.
      def current_state
        self.send(self.class.state_column).to_sym
      end

      # Returns what the next state for a given event would be, as a Ruby symbol.
      def next_state_for_event(event)
        ns = next_states_for_event(event)
        ns.empty? ? nil : ns.first.to
      end

      def next_states_for_event(event)
        self.class.read_inheritable_attribute(:transition_table)[event.to_sym].select do |s|
          s.from == current_state
        end
      end

      def run_transition_action(action)
        Symbol === action ? self.method(action).call : action.call(self)
      end
      private :run_transition_action

      def event=(event_name)
        self.send( (event_name.to_s+'!').to_sym )
      end

      def event
        ev = valid_events
        return ev ? ev.first : nil
      end

      def event_states_table
        t = {}
        state_events_table.each do |k,v|
          v.each do |vi|
            t[vi] ||= []
            t[vi].push k
          end
        end
        t
      end

      def valid_events_from_state(from_state)
        return state_events_table[from_state]
      end

      def valid_events
        valid_events_from_state(current_state)
      end

    end

    module ClassMethods
      # Returns an array of all known states.
      def states
        read_inheritable_attribute(:states).keys
      end

      def primary_states
        read_inheritable_attribute(:primary_states)
      end

      def hidden_states
        read_inheritable_attribute(:hidden_states)
      end

      def states_table
        read_inheritable_attribute(:states)
      end

      def state_options(state)
        read_inheritable_attribute(:states)[state].opts
      end

      # Define an event.  This takes a block which describes all valid transitions
      # for this event.
      #
      # Example:
      #
      # class Order < ActiveRecord::Base
      #   acts_as_funnel_state_machine :initial => :open
      #
      #   state :open, :primary=>true
      #   state :closed
      #
      #   funnel_event :close_order do
      #     transitions :to => :closed, :from => :open
      #   end
      # end
      #
      # +transitions+ takes a hash where <tt>:to</tt> is the state to transition
      # to and <tt>:from</tt> is a state (or Array of states) from which this
      # event can be fired.
      #
      # This creates an instance method used for firing the event.  The method
      # created is the name of the event followed by an exclamation point (!).
      # Example: <tt>order.close_order!</tt>.
      def funnel_event(event, opts={}, &block)
        tt = read_inheritable_attribute(:transition_table)
        state_events_table = read_inheritable_attribute(:state_events_table)

        et = read_inheritable_attribute(:event_table)
        e = et[event.to_sym] = SupportingClasses::Event.new(event, opts, tt, state_events_table, self, &block)

        define_method("#{event.to_s}!") do |*values|
          raise ArgumentError, "wrong number of arguments (#{values.size} for 1)" if values.length > 1
          data = values.first.nil? ? {} : values.first
          e.fire(self, data)
        end
      end

      # Define a state of the system. +funnel_state+ can take an optional Proc object
      # which will be executed every time the system transitions into that
      # funnel_state.  The proc will be passed the current object.
      #
      # Example:
      #
      # class Order < ActiveRecord::Base
      #   acts_as_funnel_state_machine :initial => :open
      #
      #   funnel_state :open
      #   funnel_state :closed, Proc.new { |o| Mailer.send_notice(o) }
      # end
      def funnel_state(name, opts={})
        funnel_state = SupportingClasses::State.new(name.to_sym, opts)
        read_inheritable_attribute(:states)[name.to_sym] = funnel_state

        state_events_table[name.to_sym] = []

        define_method("#{funnel_state.name}?") { current_state == funnel_state.name }

        read_inheritable_attribute(:primary_states) << name.to_sym if opts[:primary]==true
        read_inheritable_attribute(:hidden_states) << name.to_sym if opts[:hidden]==true
      end

      # Wraps ActiveRecord::Base.find to conveniently find all records in
      # a given state.  Options:
      #
      # * +number+ - This is just :first or :all from ActiveRecord +find+
      # * +state+ - The state to find
      # * +args+ - The rest of the args are passed down to ActiveRecord +find+
      def find_in_state(number, state, *args)
        with_state_scope state do
          find(number, *args)
        end
      end

      # Wraps ActiveRecord::Base.count to conveniently count all records in
      # a given state.  Options:
      #
      # * +state+ - The state to find
      # * +args+ - The rest of the args are passed down to ActiveRecord +find+
      def count_in_state(state, *args)
        with_state_scope state do
          count(*args)
        end
      end

      # Wraps ActiveRecord::Base.calculate to conveniently calculate all records in
      # a given state.  Options:
      #
      # * +state+ - The state to find
      # * +args+ - The rest of the args are passed down to ActiveRecord +calculate+
      def calculate_in_state(state, *args)
        with_state_scope state do
          calculate(*args)
        end
      end

      protected
      def with_state_scope(state)
        raise InvalidState unless states.include?(state)

        with_scope :find => {:conditions => ["#{table_name}.#{state_column} = ?", state.to_s]} do
          yield if block_given?
        end
      end
    end
  end
end
