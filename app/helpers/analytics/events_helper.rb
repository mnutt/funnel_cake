module Analytics::EventsHelper

  def state_position(state)
    Analytics::Visitor.primary_states.index(state.to_sym) * 120
  end

end
