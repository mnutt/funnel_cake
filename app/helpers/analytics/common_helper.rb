module Analytics::CommonHelper
  unloadable if RAILS_ENV=='development'

  include FunnelCake::StatePeriodHelpers

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

  def state_graph_visitors(start_state, end_state, opts)
    visitors = FunnelCake.engine.moved_to_state(end_state, opts).find.to_a
    FunnelCake::DataHash[*visitors.collect do |visitor|
      [visitor.id, FunnelCake::DataHash[visitor.to_funnelcake]]
    end.flatten]
  end

  def global_statistic_options_for_select(stat, options={})
    options = options.reverse_merge(:limit=>20)
    arr = FunnelCake.engine.global_statistic_results(stat, options).collect{|doc| [doc['_id'], doc['_id']]}
    options_for_select([['', '']] + arr, :selected=>'')
  end

end
