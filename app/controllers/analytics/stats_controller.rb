class Analytics::StatsController < Analytics::CommonController

  # def index
  #   respond_to do |format|
  #     format.html # show.html.erb
  #   end
  # end
  #

  def show
    unless params[:date_range_start].blank? or params[:date_range_end].blank?
      @date_range = params[:date_range_start].to_date..params[:date_range_end].to_date
    else
      @date_range = 1.month.ago..0.days.ago
    end
    @stat = params[:id]

    @options = add_filter_options({:date_range=>@date_range})

    if @stat == 'entered_state_count'
      state = params[:state].to_sym
      @title = state.to_s.titleize
      @value = FunnelCake::Engine.find_by_ending_state(state, @options).length
      @stat_name = "#{@stat}-#{state}"
    else
      @title = 'Unknown'
      @value = 0
      @stat_name = ''
    end

    respond_to do |format|
      format.html
      format.js
    end
  end




end
