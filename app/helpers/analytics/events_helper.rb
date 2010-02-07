module Analytics::EventsHelper
  unloadable if RAILS_ENV=='development'

  def state_position(state)
    Analytics::Visitor.primary_states.index(state.to_sym) * 120
  end

end
