
module FunnelCake
  module HasFunnel
    
    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def has_funnel(opts={})
          
          # Set up the FunnelEvent model association
          params = {:class_name=>'FunnelEvent'}
          params[:class_name] = opts[:class_name] unless opts[:class_name].nil?
          params[:foreign_key] = opts[:foreign_key] unless opts[:foreign_key].nil?
          has_many :funnel_events, params
          
          # Set up the state machine, and give it an initial unknown state
          acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false, 
                                                           :log_transitions=>true,
                                                           :error_on_invalid_transition=>false
          state :unknown
          
          # include the instance methods
          include FunnelCake::HasFunnel::UserExtensions::InstanceMethods
        end
        
        # Wrap the state machine event, so we can add a funnel_ prefix
        def funnel_event(name, &block)
          funnel_name = "funnel_#{name}".to_sym
          event(funnel_name, block)
        end
        
        # Specialized method for finding users who are "eligible" for
        # transitioning from a given state, for a given time period
        # (Used in calculating conversion rates)
        # We qualify users who:
        # - entered the given state before the end of the date range
        # MINUS
        # - exited the given state before the beginning of the date range
        def find_by_starting_state(state, opts={})
          state = state.to_sym
          return [] unless self.states.include?(state)
          
          join_frags, condition_frags = [], []
          date_range = opts.delete(:date_range)

          join_frags << "INNER JOIN funnel_events as ev0 ON users.id = ev0.user_id"
          condition_frags << "ev0.to = '#{state}'"
          condition_frags << "ev0.created_at < '#{date_range.end.to_s(:db)}'" unless date_range.nil?
          condition_frags << opts[:conditions] unless opts[:conditions].nil?
          
          a = find(:all, :readonly => false,
                         :joins => join_frags.join(" "),
                         :conditions => condition_frags.join(" AND "))
          
          join_frags, condition_frags = [], []
          join_frags << "INNER JOIN funnel_events as ev1 ON users.id = ev1.user_id"          
          condition_frags << "ev1.from = '#{state}'"
          condition_frags << "ev1.created_at < '#{date_range.begin.to_s(:db)}'" unless date_range.nil?
          condition_frags << opts[:conditions] unless opts[:conditions].nil?

          b = find(:all, :readonly => false,
                         :joins => join_frags.join(" "),
                         :conditions => condition_frags.join(" AND "))

          return a.uniq - b.uniq
        end
        
        # Specialized method for finding users who transitioned
        # into a given state, from a given state, for a given time period
        # (Used in calculating conversion rates)
        # We qualify users who:
        # - exited the start state during the date range
        # AND
        # - entered the end state during the date range
        def find_by_state_pair(start_state, end_state, opts={})
          start_state = start_state.to_sym
          end_state = end_state.to_sym
          return [] unless self.states.include?(start_state)
          return [] unless self.states.include?(end_state)          
          
          date_range = opts.delete(:date_range)          
          join_frags, condition_frags = [], []
          
          join_frags << "INNER JOIN funnel_events as ev0 ON users.id = ev0.user_id"
          join_frags << "INNER JOIN funnel_events as ev1 ON users.id = ev1.user_id"          
          condition_frags << "ev0.from = '#{start_state}'"
          condition_frags << "ev1.to = '#{end_state}'"
          unless date_range.nil?
            condition_frags << "ev0.created_at >= '#{date_range.begin.to_s(:db)}'"
            condition_frags << "ev0.created_at <= '#{date_range.end.to_s(:db)}'"          
            condition_frags << "ev1.created_at >= '#{date_range.begin.to_s(:db)}'"
            condition_frags << "ev1.created_at <= '#{date_range.end.to_s(:db)}'"          
          end
          condition_frags << opts[:conditions] unless opts[:conditions].nil?

          find(:all, :readonly => false,
               :joins => join_frags.join(" "),
               :conditions => condition_frags.join(" AND ")).uniq
        end        

        
        # Specialized method for finding users who transitioned
        # into a given state, from a given state, WITH NO STATES INBETWEEN, 
        # for a given time period
        # We qualify users who:
        # - exited the start state during the date range
        # AND
        # - entered the end state during the date range
        def find_by_transition(start_state, end_state, opts={})
          start_state = start_state.to_sym
          end_state = end_state.to_sym
          return [] unless self.states.include?(start_state)
          return [] unless self.states.include?(end_state)          
          
          join_frags, condition_frags = [], []
          date_range = opts.delete(:date_range)          
          
          join_frags << "INNER JOIN funnel_events as ev0 ON users.id = ev0.user_id"
          condition_frags << "ev0.from = '#{start_state}'"
          condition_frags << "ev0.to = '#{end_state}'"
          unless date_range.nil?
            condition_frags << "ev0.created_at >= '#{date_range.begin.to_s(:db)}'"
            condition_frags << "ev0.created_at <= '#{date_range.end.to_s(:db)}'"          
          end
          condition_frags << opts[:conditions] unless opts[:conditions].nil?

          find(:all, :readonly => false,
               :joins => join_frags.join(" "),
               :conditions => condition_frags.join(" AND ")).uniq
        end        

        # Calculate conversion rate between two states
        # By calculating the number of users in the end state, 
        # divided by the number of users in the start state
        def conversion_rate(start_state, end_state, opts={})
          top = find_by_state_pair(start_state, end_state, opts)
          bottom = find_by_starting_state(start_state, opts)
          return 0.0 if bottom.empty?
          return top.count.to_f / bottom.count.to_f
        end
        
      end
      
      module InstanceMethods
        
        def log_transition(from, to, event, data, opts)  
          self.funnel_events.create( :from=>from.to_s, :to=>to.to_s, 
                                    :url=>data[:url], :name=>event.to_s)
        end
        
      end
    end
    
  end
end