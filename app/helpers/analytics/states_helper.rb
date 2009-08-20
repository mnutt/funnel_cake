module Analytics::StatesHelper

  def state_graph_data(state, options)
    prev_state = previous_state_from(state)
    conversion_graph_data(prev_state, state, options)
  end

  def state_graph_table_data(state, options)
    prev_state = previous_state_from(state)
    conversion_graph_table_data(prev_state, state, options)
  end


  def conversion_data_hash(state, next_state, options)
    Rails.cache.fetch("FunnelCake::StatesHelper.state_graph_data:#{state}-#{options.inspect}", :expires_in=>1.day) do
      time_period = @options[:time_period]

      periods_per_year = (1.year / time_period).round

      num_periods = 6.months / time_period
      current_period_num = ((DateTime.now.beginning_of_day - DateTime.now.beginning_of_year).days.to_f / time_period.to_f).floor
      current_period = current_period(time_period)

      data_hash = { :rate=>[], :number=>[], :xaxis_ticks=>[] }
      0.upto(num_periods-1) do |period_num|
        stats = FunnelCake::Engine.conversion_stats(state, next_state, {:date_range=>current_period, :attrition_period=>time_period}.merge(options) )
        data_hash[:rate] << [ current_period_num - period_num, stats[:rate]*100.0 ]
        data_hash[:number] << [ current_period_num - period_num, stats[:end_count] ]
        if (period_num % 2 == 0) and (time_period == 1.week)
          data_hash[:xaxis_ticks] << [ current_period_num - period_num, '' ]
        else
          data_hash[:xaxis_ticks] << [ current_period_num - period_num, current_period.end.to_formatted_s(:month_slash_day) ]
        end
        current_period = (current_period.begin - time_period)...current_period.begin
      end

      data_hash
    end
  end

  def conversion_graph_data(state, next_state, options)
    data_hash = conversion_data_hash(state, next_state, options)

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

  def conversion_graph_table_data(state, next_state, options)
    data_hash = conversion_data_hash(state, next_state, options)

    table_data = "<tr class='state_graph_table_header'>
			<th>Date</th>
			<th>Value</th>
		</tr>"
    data_hash[:number].each_with_index do |number, i|
      table_data += render 'analytics/states/graph_table_row', :value=>number[1].to_i, :date=>data_hash[:xaxis_ticks][i][1]
    end

    table_data
  end


end