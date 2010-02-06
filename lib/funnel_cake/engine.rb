require 'digest/md5'
require 'funnel_cake/state_period_helpers'

module FunnelCake
  class Engine

    extend FunnelCake::StatePeriodHelpers

    # Accessor and default for User class
    @@user_class = User if Object.const_defined?('User')
    cattr_accessor :user_class

    # Accessor and default for Analytics::Visitor class
    @@visitor_class = Analytics::Visitor
    cattr_accessor :visitor_class

    # Accessor and default for Analytics::Event class
    @@event_class = Analytics::Event
    cattr_accessor :event_class


    # Helper class that DRY's up building mongo queries with a simple DSL
    # Example:
    # Finder.results(visitor_class, opts) do
    #   to state
    #   created_at :lt=>some_time
    #   where 'something'
    # end
    class Finder
      attr_accessor :options, :type, :klass

      class << self
        def results(_klass, _options={}, _type=:find, &block)
          finder = self.new(_klass, _options, _type)
          finder.instance_eval(&block)
          finder.execute
        end
      end

      def initialize(_klass, _options={}, _type=:find)
        @options = _options
        @klass = _klass
        @type = _type
        @finder_options = {}
      end

      def execute
        process_options!
        case type
        when :count
          klass.count(@finder_options)
        else
          klass.all(@finder_options)
        end
      end

      #
      # DSL methods
      #
      def from(state)
        @finder_options[:events] ||= {}
        @finder_options[:events]['$elemMatch'] ||= {}
        @finder_options[:events]['$elemMatch'][:from] = state.to_s
      end
      def to(state)
        @finder_options[:events] ||= {}
        @finder_options[:events]['$elemMatch'] ||= {}
        @finder_options[:events]['$elemMatch'][:to] = state.to_s
      end

      def has_event_with(attrib, value)
        @finder_options ||= {}
        @finder_options["events.#{attrib}"] = value
      end
      def first_event_with(attrib, value)
        @finder_options ||= {}
        @finder_options["events.0.#{attrib}"] = value
      end
      def visitor_with(attrib, value)
        @finder_options ||= {}
        @finder_options[attrib] = value
      end

      def created_at(_options={})
        @finder_options[:events] ||= {}
        @finder_options[:events]['$elemMatch'] ||= {}
        @finder_options[:events]['$elemMatch'][:created_at] ||= {}
        @finder_options[:events]['$elemMatch'][:created_at]['$lt'] = _options[:lt] if _options[:lt]
        @finder_options[:events]['$elemMatch'][:created_at]['$lte'] = _options[:lte] if _options[:lte]
        @finder_options[:events]['$elemMatch'][:created_at]['$gt'] = _options[:gt] if _options[:gt]
        @finder_options[:events]['$elemMatch'][:created_at]['$gte'] = _options[:gte] if _options[:gte]
      end

      def where(_where)
        @finder_options ||= {}
        @finder_options['$where'] = _where unless _where.blank?
      end

      private

      def process_options!
        @options[:has_event_with].each do |k,v|
          has_event_with k, v
        end if @options[:has_event_with]

        @options[:first_event_with].each do |k,v|
          first_event_with k, v
        end if @options[:first_event_with]

        @options[:visitor_with].each do |k,v|
          visitor_with k, v
        end if @options[:visitor_with]
      end
    end

    # Method for finding visitors who are "eligible" for
    # transitioning from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state before the end of the date range (but within the attrition timeframe)
    # MINUS
    # - exited the given state before the beginning of the date range
    def self.eligible_to_transition_from_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless visitor_class.states.include?(state)

      date_range = opts.delete(:date_range)
      attrition_period = opts.delete(:attrition_period)
      attrition_period = visitor_class.state_options(state)[:attrition_period] unless visitor_class.state_options(state)[:attrition_period].nil?
      attrition_period = (date_range.end - date_range.begin)*2.0 if attrition_period and attrition_period > ((date_range.end - date_range.begin)*2.0)

      js_condition = "x.from == '#{state}'"
      js_condition += " && x.created_at < new Date('#{date_range.begin.utc.to_time}')" if date_range
      where_javascript = <<-eos
        function() {
          qual=true;
          this.events.forEach(
            function(x) {
              if( #{js_condition} ) {
                qual=false;
              }
            }
          )
          return qual;
        }
      eos

      Finder.results(visitor_class, opts) do
        to state
        created_at :lt=>date_range.end.utc.to_time if date_range
        created_at :gt=>(date_range.end - attrition_period).utc.to_time if date_range and attrition_period
        where where_javascript
      end.to_a
    end


    # Method for finding visitors who transitioned
    # from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the given state during the date range
    def self.transitioned_from_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless Analytics::Visitor.states.include?(state)

      date_range = opts.delete(:date_range)

      Finder.results(visitor_class, opts) do
        from state
        created_at :gte=>date_range.begin.utc.to_time, :lte=>date_range.end.utc.to_time if date_range
      end.to_a
    end

    # Method for finding visitors who transitioned
    # into a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state during the date range
    def self.transitioned_to_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless Analytics::Visitor.states.include?(state)

      date_range = opts.delete(:date_range)

      Finder.results(visitor_class, opts) do
        to state
        created_at :gte=>date_range.begin.utc.to_time, :lte=>date_range.end.utc.to_time if date_range
      end.to_a
    end

    # Method for finding visitors who transitioned
    # into a given state, from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.transitioned_between_states(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless Analytics::Visitor.states.include?(start_state)
      return [] unless Analytics::Visitor.states.include?(end_state)

      leaving_a_user_visitors = transitioned_from_state(start_state, opts)
      entering_b_user_visitors = transitioned_to_state(end_state, opts)

      leaving_a_user_visitors.delete_if {|v| not entering_b_user_visitors.include?(v) }
    end


    # Method for finding visitors who transitioned
    # into a given state, from a given state, WITH NO STATES INBETWEEN,
    # for a given time period
    # We qualify visitors who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.transitioned_directly_between_states(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless Analytics::Visitor.states.include?(start_state)
      return [] unless Analytics::Visitor.states.include?(end_state)

      date_range = opts.delete(:date_range)

      Finder.results(visitor_class, opts) do
        from start_state
        to end_state
        created_at :gte=>date_range.begin.utc.to_time, :lte=>date_range.end.utc.to_time if date_range
      end.to_a
    end


    # Calculate stats for transitions between two states
    def self.transition_stats(start_state, end_state, opts={})
      cache_fetch("transition_stats:#{start_state}-#{end_state}-#{self.hash_options(opts)}", :expires_in=>1.day) do
        if start_state.nil? or end_state.nil?
          {:end_count=>0, :start_count=>0}
        else
					starting_visitors = eligible_to_transition_from_state(start_state, opts)
          visitors = transitioned_directly_between_states(start_state, end_state, opts)
          stats = FunnelCake::DataHash.new
          stats[:start_count] = starting_visitors.length
          stats[:end_count] = visitors.length
          stats
        end
      end
    end

    # Calculate conversion stats between two states
    def self.conversion_stats(start_state, end_state, opts={})
      cache_fetch("conversion_stats:#{start_state}-#{end_state}-#{self.hash_options(opts)}", :expires_in=>1.day) do
        if start_state.nil? or end_state.nil?
          {:rate=>0.0, :end_count=>0, :start_count=>0}
        else
          visitors = conversion_visitors(start_state, end_state, opts)
          stats = FunnelCake::DataHash.new
          stats[:end_count] = visitors[:end].length
          stats[:start_count] = visitors[:start].length

          stats[:rate] = 0.0
          stats[:rate] = stats[:end_count].to_f / stats[:start_count].to_f if stats[:start_count] > 0
          stats
        end
      end
    end

    # Calculate conversion rate between two states
    def self.conversion_rate(start_state, end_state, opts={})
      conversion_stats(start_state, end_state, opts)[:rate]
    end

    # Helper method to return visitors who correspond to conversion rate stats between states
    def self.conversion_visitors(start_state, end_state, opts={})
      if start_state.nil? or end_state.nil?
        {:end=>[], :start=>[]}
      else
        converted_visitors = self.transitioned_to_state(end_state, opts)
        starting_state_visitors = self.eligible_to_transition_from_state(start_state, opts).to_a | converted_visitors
        visitors = FunnelCake::DataHash.new
        visitors[:end] = converted_visitors
        visitors[:start] = starting_state_visitors
        visitors
      end
    end

    def self.conversion_history(start_state, end_state, options={})
      cache_fetch("conversion_history:#{start_state}-#{end_state}-#{self.hash_options(options)}", :expires_in=>1.day) do
        time_period = options[:time_period]

        periods_per_year = (1.year / time_period).round

        num_periods = (options[:max_history] || 4).months / time_period
        current_period_num = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_f / time_period.to_f).floor
        current_period = current_period(time_period)

        data_hash = FunnelCake::DataHash.new
        0.upto(num_periods-1) do |period_num|
          stats = FunnelCake::Engine.conversion_stats(start_state, end_state, {:date_range=>current_period, :attrition_period=>time_period}.merge(options) )
          data_hash[current_period_num - period_num] = FunnelCake::DataHash[{
            :rate => stats[:rate]*100.0,
            :number => stats[:end_count],
            :date => current_period.end.to_formatted_s(:month_slash_day),
            :index => current_period_num - period_num
          }]

          current_period = previous_date_range(current_period, time_period==30.days)
        end

        data_hash
      end
    end


    # Clears the cached data, by performing the memcached namespace hack
    # We find the FunnelCake namespace key, and increment it
    def self.clear_cached_data
      namespace_key = Rails.cache.fetch("FC.namespace_key") do
        rand(10000)
      end
      Rails.cache.write("FC.namespace_key", (namespace_key.to_i + 1).to_s)
    end


    private

    # Filters Visitors from a list per an options hash
    # For example:
    # :has_event_with=>{ :url=>'/some_url' }
    # :has_event_matching=>{ :url=>'url_match' }
    # or...
    # :first_event_with=>{ :referer=>'/referer_url' }
    # :first_event_matching=>{ :referer=>'referer_match' }
    def self.filter_visitors(visitors, opts={})

      opts[:has_event_with].each do |filter, value|
        visitors.delete_if { |v| v.events.find(:first, :conditions=>["#{filter} = ?", value]).nil? } unless value.blank?
      end if opts[:has_event_with]

      opts[:has_event_matching].each do |filter, value|
        visitors.delete_if { |v| v.events.find(:first, :conditions=>"#{filter} LIKE '%#{value}%'").nil? } unless value.blank?
      end if opts[:has_event_matching]

      opts[:first_event_with].each do |filter, value|
        visitors.delete_if { |v| v.events.first.attributes[filter.to_s] != value } unless value.blank?
      end if opts[:first_event_with]

      opts[:first_event_matching].each do |filter, value|
        visitors.delete_if do |v|
          (v.events.first.attributes[filter.to_s] ? v.events.first.attributes[filter.to_s].match(value) : nil).nil? unless value.blank?
        end
      end if opts[:first_event_matching]

      return visitors
    end

    # Return the namespaced key for funnelcake, so that we can easily clear the funnelcake cache
    # without blowing away all other cached data
    def self.cache_key_for(key_name)
      namespace_key = Rails.cache.fetch("FC.namespace_key") do
        rand(10000).to_s
      end
      "FC.#{namespace_key}.#{key_name}"
    end

    # Query the Rails cache, sheparded through our memcached namespace hack
    def self.cache_fetch(key, options, &block)
      Rails.cache.fetch(cache_key_for(key), options, &block)
    end

		# Returns a MD5 hash code from the inspected options hash
		def self.hash_options(options)
			Digest::MD5.hexdigest(options.inspect)
		end

  end
end
