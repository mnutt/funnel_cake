class Analytics::EventsController < Analytics::CommonController

  helper 'analytics/stats'

  def index
    limit = params[:limit].nil? ? 25 : params[:limit]

    respond_to do |format|
      format.html do
        @events = Analytics::Event.find(:all, :limit=>limit, :include=>[:visitor], :order=>'created_at DESC')
      end
      format.js do
        timestamp = params[:timestamp].to_datetime
        @events = Analytics::Event.find(:all, :limit=>limit, :include=>[:visitor],
                                                :order=>'created_at DESC', :conditions=>['created_at > ?',timestamp])
      end
    end
  end

  # GET /events/1
  def show
    @event = Analytics::Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def diagram
    @daterange = params[:start_days_ago].to_i.days.ago .. 0.days.ago
    @options = add_filter_options({:date_range=>@daterange, :attrition_period=>1.month})
    respond_to do |format|
      format.js { render }
    end
  end

  def overview
  end

end
