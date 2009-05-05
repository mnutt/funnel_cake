class FunnelVisitor < ActiveRecord::Base
  # Set up the FunnelEvent model association
  has_many :funnel_events, :class_name=>'FunnelEvent'
  
  # Set up state machine           
  acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false, 
                                :log_transitions=>true,
                                :error_on_invalid_transition=>false
  state :unknown
  self.extend FunnelCake::UserStates
  initialize_states
  
  # Add association for User model
  belongs_to :user, :class_name=>'User', :foreign_key=>:user_id
  

  # Create a FunnelEvent, as a callback to a state_machine transition
  def log_transition(from, to, event, data, opts)  
    self.funnel_events.create( :from=>from.to_s, :to=>to.to_s, 
                              :url=>data[:url], 
                              :referer=>data[:referer],
                              :user_agent=>data[:user_agent],
                              :name=>event.to_s)
  end
  
  # Utility method for logging funnel events from within application code
  # (This is probably how most funnel events will be triggered)
  # - First check if the event is legal... if not, log an error I guess!
  # - Second, send() the event method with the accompanying data
  def log_funnel_event(event, data={})
    unless self.valid_events.include?(event.to_sym)
      logger.info "#{self.class.to_s} couldn't log FunnelCake event: #{event} This event is not valid for state: #{self.current_state}, ip: #{self.ip}" 
      return
    end
    self.send(event.to_s+"!", data)
  end

end
