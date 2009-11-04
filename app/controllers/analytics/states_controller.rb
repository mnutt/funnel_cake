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
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        date_range = grab_date_range
        time_period = params[:time_period].to_i.days
        end_state = @state.to_sym
        start_state = previous_state_from(end_state)
        stat = params[:stat].blank? ? :number : params[:stat].to_sym
        options = add_filter_options({:time_period=>time_period, :stat=>stat})
        render :json=>FunnelCake::Engine.conversion_history(start_state, end_state, options).to_json and return
      end
    end
  end

end
