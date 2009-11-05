module Analytics::CommonHelper

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
    visitors = FunnelCake::Engine.conversion_visitors(start_state, end_state, opts)

    starting_visitors = visitors[:start].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    ending_visitors = visitors[:end].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }

    FunnelCake::DataHash[{
      :start_state=>FunnelCake::DataHash[*starting_visitors.collect { |visitor| [visitor.id, collapse_visitor_attributes(visitor)] }.flatten],
      :end_state=>FunnelCake::DataHash[*ending_visitors.collect { |visitor| [visitor.id, collapse_visitor_attributes(visitor)] }.flatten]
    }]
  end

  def collapse_visitor_attributes(visitor)
    attrs = visitor.attributes.merge({:email=>nil, :name=>nil, :recent_event_date=>nil})

    if visitor.user
      attrs[:email] = visitor.user.email
      attrs[:name] = visitor.user.name
    end
    attrs[:recent_event_date] = visitor.events.last.created_at.to_s(:short)

    FunnelCake::DataHash[attrs]
  end

end