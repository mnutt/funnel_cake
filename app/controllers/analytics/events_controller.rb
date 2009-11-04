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

end
