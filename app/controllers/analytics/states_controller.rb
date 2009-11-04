class Analytics::StatesController < Analytics::CommonController
  helper 'analytics/common'
  helper 'analytics/stats'
  include Analytics::ConversionsHelper

  def index
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def show
    @state = params[:id]
    date_range = grab_date_range
    time_period = params[:time_period].to_i.days
    end_state = @state.to_sym
    start_state = previous_state_from(end_state)
    stat = params[:stat].blank? ? :number : params[:stat].to_sym
    options = add_filter_options({:time_period=>time_period, :stat=>stat})

    respond_to do |format|
      format.html # show.html.erb
      format.json do
        render :json=>FunnelCake::Engine.conversion_history(start_state, end_state, options).to_json and return
      end
      format.csv do
        render :inline=>FunnelCake::Engine.conversion_history(start_state, end_state, options).to_csv and return
      end
    end
  end

  def visitors
    @state = params[:id]
    date_range = grab_date_range
    time_period = params[:time_period].to_i.days
    end_state = @state.to_sym
    start_state = previous_state_from(end_state)
    stat = params[:stat].blank? ? :id : params[:stat].to_sym
    options = add_filter_options({:date_range=>date_range, :stat=>stat})

    visitors = state_graph_visitors(start_state, end_state, options)

    respond_to do |format|
      format.json do
        render :json=>visitors[:end_state].to_json and return
      end
      format.csv do
        render :inline=>visitors[:end_state].to_csv and return
      end
    end
  end

end
