require 'digest/md5'
require 'funnel_cake/state_period_helpers'
# gem 'rainbow'
# require 'rainbow'

module FunnelCake::DataStore::MongoMapper
  class Engine < FunnelCake::Engine

    # Helper class that DRY's up building mongo queries with a simple DSL
    # Example:
    # Finder.new(visitor_class, opts) do
    #   to state
    #   created_at :lt=>some_time
    #   where 'something'
    # end.find
    class Finder
      attr_accessor :options, :klass

      def initialize(_klass, _options={}, &block)
        @options = _options
        @klass = _klass
        @finder_options = {}
        self.instance_eval(&block)
      end

      def execute(type=:find)
        process_options!
        # puts "FunnelCake Query: #{type} - #{@finder_options.inspect}".color(:green)
        case type
        when :count
          klass.count(@finder_options)
        else
          klass.all(@finder_options)
        end
      end
      def find; execute; end
      def count; execute(:count); end

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
        @finder_options[:events]['$elemMatch'][:created_at]['$lt'] = _options[:lt].to_time.utc.to_time unless _options[:lt].blank?
        @finder_options[:events]['$elemMatch'][:created_at]['$lte'] = _options[:lte].to_time.utc.to_time unless _options[:lte].blank?
        @finder_options[:events]['$elemMatch'][:created_at]['$gt'] = _options[:gt].to_time.utc.to_time unless _options[:gt].blank?
        @finder_options[:events]['$elemMatch'][:created_at]['$gte'] = _options[:gte].to_time.utc.to_time unless _options[:gte].blank?
      end

      def where(_where)
        @finder_options ||= {}
        @finder_options['$where'] = _where unless _where.blank?
      end

      private

      def process_options!
        @options[:has_event_with].each do |k,v|
          has_event_with k, v unless v.blank?
        end if @options[:has_event_with]

        @options[:first_event_with].each do |k,v|
          first_event_with k, v unless v.blank?
        end if @options[:first_event_with]

        @options[:visitor_with].each do |k,v|
          visitor_with k, v unless v.blank?
        end if @options[:visitor_with]
      end
    end

    # Method for finding visitors who are "eligible" for
    # moveing from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state before the end of the date range (but within the attrition timeframe)
    # MINUS
    # - exited the given state before the beginning of the date range
    def self.eligible_to_move_from_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless visitor_class.states.include?(state)

      date_range = opts[:date_range]
      attrition_period = opts.delete(:attrition_period)
      attrition_period = visitor_class.state_options(state)[:attrition_period] unless visitor_class.state_options(state)[:attrition_period].nil?
      attrition_period = ((date_range.end - date_range.begin)*2.0).days if attrition_period and attrition_period > ((date_range.end - date_range.begin)*2.0).days

      js_condition = "x.from == '#{state}'"
      js_condition += " && x.created_at < new Date('#{mongo_date(date_range.begin)}')" if date_range
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

      Finder.new(visitor_class, opts) do
        to state
        created_at :lt=>date_range.end if date_range
        created_at :gt=>(date_range.begin - attrition_period) if date_range and attrition_period
        where where_javascript
      end
    end


    # Method for finding visitors who moved
    # from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the given state during the date range
    def self.moved_from_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless Analytics::Visitor.states.include?(state)

      date_range = opts[:date_range]

      Finder.new(visitor_class, opts) do
        from state
        created_at :gte=>date_range.begin, :lte=>date_range.end if date_range
      end
    end

    # Method for finding visitors who moved
    # into a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state during the date range
    def self.moved_to_state(state, opts={})
      return [] if state.nil?
      state = state.to_sym
      return [] unless Analytics::Visitor.states.include?(state)

      date_range = opts[:date_range]

      Finder.new(visitor_class, opts) do
        to state
        created_at :gte=>date_range.begin, :lte=>date_range.end if date_range
      end
    end

    # Method for finding visitors who moved
    # into a given state, from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.moved_between_states(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless Analytics::Visitor.states.include?(start_state)
      return [] unless Analytics::Visitor.states.include?(end_state)

      date_range = opts[:date_range]

      js_condition = "x.to == '#{end_state}'"
      js_condition += " && x.created_at >= new Date('#{mongo_date(date_range.begin)}')" if date_range
      js_condition += " && x.created_at <= new Date('#{mongo_date(date_range.end)}')" if date_range
      where_javascript = <<-eos
        function() {
          qual=false;
          this.events.forEach(
            function(x) {
              if( #{js_condition} ) {
                qual=true;
              }
            }
          )
          return qual;
        }
      eos

      Finder.new(visitor_class, opts) do
        from start_state
        created_at :gte=>date_range.begin, :lte=>date_range.end if date_range
        where where_javascript
      end
    end


    # Method for finding visitors who moved
    # into a given state, from a given state, WITH NO STATES INBETWEEN,
    # for a given time period
    # We qualify visitors who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.moved_directly_between_states(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless Analytics::Visitor.states.include?(start_state)
      return [] unless Analytics::Visitor.states.include?(end_state)

      date_range = opts[:date_range]

      Finder.new(visitor_class, opts) do
        from start_state
        to end_state
        created_at :gte=>date_range.begin, :lte=>date_range.end if date_range
      end
    end


    #
    # Methods for querying global stats
    #
    def self.global_statistic_results(stat, limit=20)
      MongoMapper.database.collection("analytics.statistics.#{stat.to_s.pluralize}").
      		find.sort(['value.count','descending']).limit(limit)
    end


    private

    def self.mongo_date(datetime)
      datetime.to_time.utc.to_time
    end

  end
end