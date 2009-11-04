module FunnelCake
  module StatePeriodHelpers

    def next_state_from(state)
      i = Analytics::Visitor.primary_states.index(state.to_sym)
      return Analytics::Visitor.primary_states[i+1] if i

      i = Analytics::Visitor.states.index(state.to_sym)
      Analytics::Visitor.states[i+1]
    end

    def previous_state_from(state)
      i = Analytics::Visitor.primary_states.index(state.to_sym)
      return Analytics::Visitor.primary_states[i-1] if i

      i = Analytics::Visitor.states.index(state.to_sym)
      Analytics::Visitor.states[i-1]
    end

    def day_within_current_period(time_period)
      ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_i % time_period.to_i)/1.day
    end

    def current_period(time_period)
      return 0.days.ago.beginning_of_month...0.days.ago.end_of_month if time_period==30.days
      start = day_within_current_period(time_period).days.ago.beginning_of_day
      start...(start+time_period)
    end

    def previous_date_range(date_range)
      period = date_range.end - date_range.begin
      (date_range.begin - period)..date_range.begin
    end

  end
end