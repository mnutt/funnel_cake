module Analytics::CommonHelper

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

  def previous_date_range(date_range)
    period = date_range.end - date_range.begin
    (date_range.begin - period)..date_range.begin
  end

  def state_graph_visitors(start_state, end_state, opts)
    visitors = FunnelCake::Engine.conversion_visitors(start_state, end_state, opts)

    starting_visitors = visitors[:start].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    ending_visitors = visitors[:end].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    [starting_visitors, ending_visitors]
  end

  def conversion_data_hash(state, next_state, options)
    Rails.cache.fetch("FC.state_graph_data:#{state}-#{options.inspect.gsub(/[\s:=>\"\{\}\,]/,'')}", :expires_in=>1.day) do
      time_period = options[:time_period]

      periods_per_year = (1.year / time_period).round

      num_periods = 6.months / time_period
      current_period_num = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_f / time_period.to_f).floor
      current_period = current_period(time_period)

      data_hash = {}
      0.upto(num_periods-1) do |period_num|
        stats = FunnelCake::Engine.conversion_stats(state, next_state, {:date_range=>current_period, :attrition_period=>time_period}.merge(options) )
        data_hash[current_period_num - period_num] = {
          :rate => stats[:rate]*100.0,
          :number => stats[:end_count],
          :date => current_period.end.to_formatted_s(:month_slash_day),
          :index => current_period_num - period_num
        }
        current_period = (current_period.begin - time_period)...current_period.begin
      end

      data_hash
    end
  end


end