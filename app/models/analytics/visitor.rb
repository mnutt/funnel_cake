class Analytics::Visitor
  include MongoMapper::Document
  include FunnelCake::ActsAsFunnelStateMachine
  include FunnelCake::HasFunnel::UserExtensions

  timestamps!
  key :key, String
  key :user_id, Integer
  key :state, String
  key :ip, String

  # Set up the Analytics::Event model association
  many :events, :class_name=>'Analytics::Event', :dependent=>:destroy, :foreign_key=>:visitor_id


  # Set up state machine
  acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false,
                                :log_transitions=>true,
                                :error_on_invalid_transition=>false
  funnel_state :unknown
  self.extend FunnelCake::UserStates
  initialize_states

  # Add association for User model
  belongs_to :user, :class_name=>'User', :foreign_key=>:user_id

  # Create a Analytics::Event, as a callback to a state_machine transition
  def log_transition(from, to, event, data, opts)
    self.events << Analytics::Event.create({
      :from=>from.to_s, :to=>to.to_s,
      :url=>data[:url],
      :referer=>data[:referer],
      :user_agent=>data[:user_agent],
      :name=>event.to_s
    })
    self.save
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

  def to_funnelcake
    attrs = attributes.clone
    attrs.merge(user.to_funnelcake) if user and user.responds_to?(:to_funnelcake)
    attrs[:recent_event_date] = visitor.events.last.created_at.to_s(:short)
  end

end
