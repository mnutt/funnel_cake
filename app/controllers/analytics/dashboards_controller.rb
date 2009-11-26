class Analytics::DashboardsController < Analytics::CommonController

  def diagram
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})

		json = []
		Analytics::Visitor.event_table.each do |ev_name, ev|
		  Analytics::Visitor.transition_table[ev_name].each do |trans|
				json << {
					:from => trans.from,
					:to => trans.to,
					:stats => FunnelCake::Engine.transition_stats(trans.from, trans.to, @options),
					:to_primary => Analytics::Visitor.states_table[trans.to].primary?
				}	unless Analytics::Visitor.states_table[trans.from].hidden? or Analytics::Visitor.states_table[trans.to].hidden?
		  end
		end

    respond_to do |format|
      format.json { render :json=>json.to_json and return }
    end
  end

  def overview
  end

end