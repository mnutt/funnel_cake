class Analytics::Visitor
  include FunnelCake::HasFunnel::UserExtensions

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
      Rails.logger.info "#{self.class.to_s} couldn't log FunnelCake event: #{event} This event is not valid for state: #{self.current_state}, ip: #{self.ip}"
      return
    end
    self.send(event.to_s+"!", data)
  end

end
