module FunnelCake
  class Engine
    
    # Accessor and default for User class
    @@user_class_name = 'User'
    cattr_accessor :user_class_name
    def self.user_class
      @@user_class_name.constantize
    end

    # Accessor and default for FunnelVisitor class
    @@visitor_class_name = 'FunnelVisitor'
    cattr_accessor :visitor_class_name
    def self.visitor_class
      @@visitor_class_name.constantize
    end
    
    # Accessor and default for FunnelEvent class
    @@event_class_name = 'FunnelEvent'
    cattr_accessor :event_class_name
    def self.event_class
      @@event_class_name.constantize
    end

    # Specialized method for finding users/visitors who are "eligible" for
    # transitioning from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify users who:
    # - entered the given state before the end of the date range
    # MINUS
    # - exited the given state before the beginning of the date range
    def self.find_by_starting_state(state, opts={})
      return [] if state.nil?          
      state = state.to_sym
      return [] unless FunnelVisitor.states.include?(state)
      
      date_range = opts[:date_range]

      condition_frags = []
      condition_frags << "#{event_class.table_name}.to = '#{state}'"
      condition_frags << "#{event_class.table_name}.created_at < '#{date_range.end.to_s(:db)}'" unless date_range.nil?
      condition_frags << opts[:conditions] unless opts[:conditions].nil?
      entering_a_user_visitors = FunnelVisitor.find(:all, :joins=>[:funnel_events], :conditions=>condition_frags.join(" AND "))

      condition_frags = []
      condition_frags << "#{event_class.table_name}.from = '#{state}'"
      condition_frags << "#{event_class.table_name}.created_at < '#{date_range.begin.to_s(:db)}'" unless date_range.nil?
      condition_frags << opts[:conditions] unless opts[:conditions].nil?
      leaving_a_user_visitors = FunnelVisitor.find(:all, :joins=>[:funnel_events], :conditions=>condition_frags.join(" AND "))
      
      return entering_a_user_visitors - leaving_a_user_visitors
    end    
    

    # Specialized method for finding users/visitors who transitioned
    # into a given state, from a given state, for a given time period
    # (Used in calculating conversion rates)
    # We qualify users who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.find_by_state_pair(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless FunnelVisitor.states.include?(start_state)
      return [] unless FunnelVisitor.states.include?(end_state)          
      
      date_range = opts[:date_range]          
      
      condition_frags = []
      condition_frags << "#{event_class.table_name}.from = '#{start_state}'"
      condition_frags << "#{event_class.table_name}.created_at >= '#{date_range.begin.to_s(:db)}'" unless date_range.nil?
      condition_frags << "#{event_class.table_name}.created_at <= '#{date_range.end.to_s(:db)}'" unless date_range.nil?      
      condition_frags << opts[:conditions] unless opts[:conditions].nil?
      leaving_a_user_visitors = FunnelVisitor.find(:all, :joins=>[:funnel_events], :conditions=>condition_frags.join(" AND "))

      condition_frags = []
      condition_frags << "#{event_class.table_name}.to = '#{end_state}'"
      condition_frags << "#{event_class.table_name}.created_at >= '#{date_range.begin.to_s(:db)}'" unless date_range.nil?
      condition_frags << "#{event_class.table_name}.created_at <= '#{date_range.end.to_s(:db)}'" unless date_range.nil?      
      condition_frags << opts[:conditions] unless opts[:conditions].nil?
      entering_b_user_visitors = FunnelVisitor.find(:all, :joins=>[:funnel_events], :conditions=>condition_frags.join(" AND "))
      
      leaving_a_user_visitors & entering_b_user_visitors
    end        
            
    
    # Specialized method for finding users who transitioned
    # into a given state, from a given state, WITH NO STATES INBETWEEN, 
    # for a given time period
    # We qualify users who:
    # - exited the start state during the date range
    # AND
    # - entered the end state during the date range
    def self.find_by_transition(start_state, end_state, opts={})
      return [] if start_state.nil? or end_state.nil?          
      start_state = start_state.to_sym
      end_state = end_state.to_sym
      return [] unless FunnelVisitor.states.include?(start_state)
      return [] unless FunnelVisitor.states.include?(end_state)          
      
      date_range = opts[:date_range]          

      condition_frags = []
      condition_frags << "#{event_class.table_name}.from = '#{start_state}'"
      condition_frags << "#{event_class.table_name}.to = '#{end_state}'"      
      condition_frags << "#{event_class.table_name}.created_at >= '#{date_range.begin.to_s(:db)}'" unless date_range.nil?
      condition_frags << "#{event_class.table_name}.created_at <= '#{date_range.end.to_s(:db)}'" unless date_range.nil?      
      condition_frags << opts[:conditions] unless opts[:conditions].nil?
      user_visitors = FunnelVisitor.find(:all, :joins=>[:funnel_events], :conditions=>condition_frags.join(" AND "))

      user_visitors
    end            
    
        
    # Calculate conversion rate between two states
    # By calculating the number of users in the end state, 
    # divided by the number of users in the start state
    def self.conversion_rate(start_state, end_state, opts={})
      return 0.0 if start_state.nil? or end_state.nil?      
      
      top = self.find_by_state_pair(start_state, end_state, opts)
      bottom = self.find_by_starting_state(start_state, opts)
      
      return 0.0 if bottom.empty?
      return top.count.to_f / bottom.count.to_f
    end    
    
  end
end