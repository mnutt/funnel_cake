module Analytics::EventsHelper

  # Grab raw position data from the diagram xdot
  XDOT_FILE = File.join(RAILS_ROOT, 'app', 'views', 'analytics', 'events', '_diagram.xdot.erb')
  RAW_STATE_POSITIONS_ARR = File.open(XDOT_FILE).read.split(/\n/).
                          collect { |l| l.match(/(\w+) \[label=\".*pos=\"(\d+,\d+)\"/) }.
                          delete_if {|m| m.nil?}.
                          collect {|m| [m[1].to_sym, {:left=>m[2].split(/,/)[0].to_i, :top=>m[2].split(/,/)[1].to_i}] }
  RAW_STATE_POSITIONS = Hash[*RAW_STATE_POSITIONS_ARR.flatten]
  state_pos_bounds_matches = File.open(XDOT_FILE).read.match(/bb=\"0,0,(\d+),(\d+)\"/ms)
  STATE_POSITION_BOUNDS = {:width=>state_pos_bounds_matches[1].to_i, :height=>state_pos_bounds_matches[2].to_i}
  STATE_POSITIONS = RAW_STATE_POSITIONS.each_value{ |h| h[:top] = STATE_POSITION_BOUNDS[:height] - h[:top]; h }
  POS_PADDING = 8
  POS_SCALE = 0.6 * 96/72

  def state_position(state)
    Analytics::Visitor.primary_states.index(state.to_sym) * 120
    # pos = STATE_POSITIONS[state.to_sym]
    # return 0 if pos.nil?
    # pos[:top]*POS_SCALE - POS_PADDING
  end

  def next_state_from(state)
    i = Analytics::Visitor.primary_states.index(state.to_sym)
    Analytics::Visitor.primary_states[i+1]
  end

  def funnel_event_node_javascript(state, daterange)
    next_state = next_state_from(state)
    stats = FunnelCake::Engine.conversion_stats(state, next_state, {:date_range=>daterange, :attrition_period=>1.month})
    cur_node = "{\n"
    cur_node += "    name: '#{state.to_s.titleize}',\n"
    cur_node += "    id: '#{state.to_s}',\n"
    cur_node += "    position: {x: 0, y: #{state_position(state)}},\n"
    cur_node += "    size: {width: 200, height: 23},\n"
    cur_node += "    rate: '<span class=\"count_stats\">#{stats[:start_count].to_i}</span><span class=\"rate_stats\"><br />#{number_to_percentage(stats[:rate]*100.0, :precision=>1)}</span><br /><span class=\"count_stats\">#{stats[:end_count].to_i}</span>'\n"
    cur_node += "  }"
    cur_node
  end

  def funnel_event_nodes_javascript(daterange)
  	node_str = 'var nodes = ['
  	node_array = []
  	Analytics::Visitor.primary_states.each_with_index do |state, i|
    	node_array << funnel_event_node_javascript(state, daterange)
  	end
  	node_str += node_array.join(",\n")
  	node_str += "].sortBy(function(s) { return s.position.y });"
  	node_str
  end

  def state_graph_data(state, time_period)
    next_state = next_state_from(state)
    periods_per_year = (1.year / time_period).round

    num_periods = 6.months / time_period
    day_within_current_period = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_i % time_period.to_i)/1.day
    current_period_num = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_f / time_period.to_f).floor
    current_period = day_within_current_period.days.ago.beginning_of_day...0.days.ago.beginning_of_day

    data_hash = { :rate=>[], :number=>[], :xaxis_ticks=>[] }
    0.upto(num_periods-1) do |period_num|
      stats = FunnelCake::Engine.conversion_stats(state, next_state, {:date_range=>current_period, :attrition_period=>time_period})
      data_hash[:rate] << [ current_period_num - period_num, stats[:rate]*100.0 ]
      data_hash[:number] << [ current_period_num - period_num, stats[:end_count] ]
      data_hash[:xaxis_ticks] << [ current_period_num - period_num, current_period.end.to_formatted_s(:month_slash_day) ]
      current_period = (current_period.begin - time_period)...current_period.begin
    end

    data_str_array = []
    data_str_array << "[{
			  data: #{data_hash[:number].inspect},
		    lines: {show: true, fill: true},
		    points: {show: true}
		}]"
  	data_str_array << "{
  	  xaxis: {
				ticks: #{ data_hash[:xaxis_ticks].inspect },		// => format: either [1, 3] or [[1, 'a'], 3]
				noTicks: 5,		// => number of ticks for automagically generated ticks
				tickFormatter: function(n){ return n; },
				tickDecimals: 0,	// => no. of decimals, null means auto
				min: null,		// => min. value to show, null means set automatically
				max: null,		// => max. value to show, null means set automatically
				autoscaleMargin: 0	// => margin in % to add if auto-setting min/max
			}"
  	data_str_array << "yaxis: {
				ticks: null,		// => format: either [1, 3] or [[1, 'a'], 3]
				noTicks: 5,		// => number of ticks for automagically generated ticks
				tickFormatter: function(n){ return n; },
				tickDecimals: 0,	// => no. of decimals, null means auto
				min: null,		// => min. value to show, null means set automatically
				max: null,		// => max. value to show, null means set automatically
				autoscaleMargin: 0	// => margin in % to add if auto-setting min/max
		  }
		}"

  	data_str_array.join(",\n")
  end

  def state_graph_visitors(state, time_period)
    opts = {:date_range=>Date.today - time_period .. Date.today, :attrition_period=>1.month}
    next_state = next_state_from(state)
    state_pair_visitors = FunnelCake::Engine.find_by_state_pair(state, next_state, opts)
    state_pair_visitors = state_pair_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    starting_state_visitors = FunnelCake::Engine.find_by_starting_state(state, opts).to_a | state_pair_visitors
    starting_state_visitors = starting_state_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    [starting_state_visitors, state_pair_visitors]
  end

end
