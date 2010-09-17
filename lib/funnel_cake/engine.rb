require 'digest/md5'
require 'funnel_cake/state_period_helpers'
# gem 'rainbow'
# require 'rainbow'

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

    # Method for finding visitors who are "eligible" for
    # moveing from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state before the end of the date range (but within the attrition timeframe)
    # MINUS
    # - exited the given state before the beginning of the date range
    def self.eligible_to_move_from_state(state, opts={})
      raise NotImplementedError, 'Method not implemented in the Engine superclass'
    end

    # Method for finding visitors who moved
    # from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the given state during the date range
    def self.moved_from_state(state, opts={})
      raise NotImplementedError, 'Method not implemented in the Engine superclass'
    end

    # Method for finding visitors who moved
    # into a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - entered the given state during the date range
    def self.moved_to_state(state, opts={})
      raise NotImplementedError, 'Method not implemented in the Engine superclass'
    end

    # Method for finding visitors who moved
    # into a given state, from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify visitors who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.moved_between_states(start_state, end_state, opts={})
      raise NotImplementedError, 'Method not implemented in the Engine superclass'
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


    # Calculate stats for moves between two states
    def self.move_stats(start_state, end_state, opts={})
      cache_fetch("move_stats:#{start_state}-#{end_state}-#{self.hash_options(opts)}", :expires_in=>1.day) do
        if start_state.nil? or end_state.nil?
          {:end=>0, :start=>0}
        else
          stats = FunnelCake::DataHash.new
          stats[:start] = eligible_to_move_from_state(start_state, opts).count
          stats[:end] = moved_directly_between_states(start_state, end_state, opts).count
          stats_with_rate(stats)
        end
      end
    end

    # Calculate conversion stats between two states
    def self.conversion_stats(start_state, end_state, opts={})
      cache_fetch("conversion_stats:#{start_state}-#{end_state}-#{self.hash_options(opts)}", :expires_in=>1.day) do
        if start_state.nil? or end_state.nil?
          {:rate=>0.0, :end=>0, :start=>0}
        else
          stats = FunnelCake::DataHash.new
          stats[:start] = eligible_to_move_from_state(start_state, opts).count
          stats[:end] = moved_to_state(end_state, opts).count
          stats_with_rate(stats)
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
        converted_visitors = moved_to_state(end_state, opts).find.to_a
        starting_state_visitors = eligible_to_move_from_state(start_state, opts).find.to_a | converted_visitors
        visitors = FunnelCake::DataHash.new
        visitors[:start] = starting_state_visitors
        visitors[:end] = converted_visitors
        visitors
      end
    end

    def self.conversion_history(start_state, end_state, options={})
      return compound_conversion_history(start_state, end_state, options) if options[:compare]
      cache_fetch("conversion_history:#{start_state}-#{end_state}-#{self.hash_options(options)}", :expires_in=>1.day) do
        time_period = options[:time_period]

        periods_per_year = (1.year / time_period).round

        num_periods = (options[:max_history] || 4).months / time_period
        current_period_num = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_f / time_period.to_f).floor
        current_period = current_period(time_period)

        data_hash = FunnelCake::DataHash.new
        0.upto(num_periods-1) do |period_num|
          stats = conversion_stats(start_state, end_state, {:date_range=>current_period, :attrition_period=>time_period}.merge(options) )
          data_hash[current_period_num - period_num] = FunnelCake::DataHash[{
            :rate => stats[:rate]*100.0,
            :number => stats[:end],
            :date => current_period.end.to_formatted_s(:month_slash_day),
            :index => current_period_num - period_num
          }]

          current_period = previous_date_range(current_period, time_period==30.days)
        end

        name = options[:name] || "#{start_state}-#{end_state}"
        FunnelCake::DataHash[{name=>data_hash}]
      end
    end

    def self.compound_conversion_history(start_state, end_state, options={})
      data_hash = FunnelCake::DataHash.new
      compares = options.delete(:compare)
      compares.each_with_index do |cur_options, i|
        cur_options[:name] = i
        data_hash.merge! conversion_history(start_state, end_state, cur_options.merge(options))
      end
      data_hash
    end


    # Clears the cached data, by performing the memcached namespace hack
    # We find the FunnelCake namespace key, and increment it
    def self.clear_cached_data
      namespace_key = Rails.cache.fetch("FC.namespace_key") do
        rand(10000)
      end
      Rails.cache.write("FC.namespace_key", (namespace_key.to_i + 1).to_s)
    end

    #
    # Methods for querying global stats
    #
    def self.global_statistic(stat, limit=20)
      raise NotImplementedError, 'Method not implemented in the Engine superclass'
    end


    private

    def self.stats_with_rate(stats)
      stats[:rate] = 0.0
      stats[:rate] = stats[:end].to_f / stats[:start].to_f if stats[:start] > 0
      stats
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
      FunnelCake::DataHash  # Preload the class so we don't get any memcache marshalling errors
      Rails.cache.fetch(cache_key_for(key), options, &block)
    end

    # Returns a MD5 hash code from the inspected options hash
    def self.hash_options(options)
      Digest::MD5.hexdigest(options.inspect)
    end

  end
end
