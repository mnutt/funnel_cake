class Analytics::ConversionsController < Analytics::CommonController
  include Analytics::ConversionsHelper

  before_filter :load_state_from_id, :only=>[:show, :history, :visitors]
  def load_state_from_id
    @start_state = params[:id].sub(/-.*/,'')
    @end_state = params[:id].sub(/[^-]*-/,'')
  end

  def index
		push_includes :google

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def show
		push_includes :google

    respond_to do |format|
      format.html # show.html.erb
      format.json do
        json = {}

        @date_range = grab_date_range
        @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
        json[:stats] = FunnelCake::Engine.conversion_stats(@start_state, @end_state, @options)

        if params[:show_previous_period]=='true'
          @previous_date_range = previous_date_range(@date_range, duration_of(@date_range)==30)
          @previous_options = add_filter_options({:date_range=>@previous_date_range, :attrition_period=>1.month})
          json[:previous_stats] = FunnelCake::Engine.conversion_stats(@start_state, @end_state, @previous_options)
        end

        render :json=>json.to_json and return
      end
    end
  end

  def visitors
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.html do
        render :partial=>'visitors',
                :locals=>{:start_state=>@start_state, :end_state=>@end_state, :options=>@options}
      end
    end
  end

  def history
    @time_period = params[:time_period].to_i.days
    @state = params[:id]
    stat = params[:stat].blank? ? :number : params[:stat].to_sym
    @options = add_filter_options({:time_period=>@time_period, :stat=>stat})
    respond_to do |format|
      format.json do
        render :json=>FunnelCake::Engine.conversion_history(@start_state, @end_state, @options).to_json and return
      end
      format.csv do
        send_data(FunnelCake::Engine.conversion_history(@start_state, @end_state, @options).to_csv,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => "#{@state}-#{params[:time_period]}day_history.csv") and return
      end
    end
  end

end
