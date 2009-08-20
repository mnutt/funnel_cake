module Analytics::CommonHelper

  def next_state_from(state)
    i = Analytics::Visitor.primary_states.index(state.to_sym)
    Analytics::Visitor.primary_states[i+1]
  end

  def previous_state_from(state)
    i = Analytics::Visitor.primary_states.index(state.to_sym)
    Analytics::Visitor.primary_states[i-1]
  end

  def day_within_current_period(time_period)
    ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_i % time_period.to_i)/1.day
  end

  def current_period(time_period)
    start = day_within_current_period(time_period).days.ago.beginning_of_day
    start...(start+time_period)
  end

  def monthly_header
    "#{Date.today.beginning_of_month.to_s(:month_year)}, #{Date.today.end_of_month.day.to_i - Date.today.day.to_i} days remaining"
  end

  def generic_header_text(period)
    cp = current_period(period)
    "#{cp.begin.to_date.to_s(:short)} to #{(cp.begin + period).to_date.to_s(:short)}, #{period.to_i/1.day - day_within_current_period(period)} days remaining"
  end

  def biweekly_header
    generic_header_text(2.weeks)
  end

  def weekly_header
    generic_header_text(1.week)
  end

end