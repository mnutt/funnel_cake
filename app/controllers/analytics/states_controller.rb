class Analytics::StatesController < Analytics::CommonController

  helper 'analytics/common'
  helper 'analytics/stats'

  def index
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def show
    @state = params[:id]
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def graph_data
    @time_period = params[:time_period].to_i.days
    @state = params[:id]
    @options = add_filter_options({:time_period=>@time_period})
    respond_to do |format|
      format.js { render }
    end
  end

  def graph_table_data
    @time_period = params[:time_period].to_i.days
    @state = params[:id]
    @options = add_filter_options({:time_period=>@time_period})
    respond_to do |format|
      format.js { render }
    end
  end



end
