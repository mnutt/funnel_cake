module Analytics::StatsHelper
  unloadable if RAILS_ENV=='development'

  def entered_state_count_stat(state, title)
    render '/analytics/stats/stat', :value=>'', :title=>title, :id=>"stat_entered_state_count-#{state}"
  end

end
