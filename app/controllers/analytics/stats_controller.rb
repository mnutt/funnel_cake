class Analytics::StatsController < Analytics::CommonController

  helper 'analytics/common'

  # def index
  #   respond_to do |format|
  #     format.html # show.html.erb
  #   end
  # end
  #

  def show
    @date_range = grab_date_range
    @stat = params[:id]

    @options = add_filter_options({:date_range=>@date_range})

    if @stat == 'entered_state_count'
      state = params[:state].to_sym
      prev_state = previous_state_from(state)
      @title = params[:title] or state.to_s.titleize
      stats = FunnelCake.engine.conversion_stats(prev_state, state, {:date_range=>@date_range, :attrition_period=>1.month}.merge(@options) )
      @value = stats[:end].to_i
      @stat_name = "#{@stat}-#{state}"
    else
      @title = params[:title] or 'Unknown'
      @value = 0
      @stat_name = ''
    end

    respond_to do |format|
      format.html
      format.js
    end
  end




end
