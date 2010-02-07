class Analytics::EventsController < Analytics::CommonController
  unloadable if RAILS_ENV=='development'

  helper 'analytics/stats'

  def index
    limit = params[:limit].nil? ? 25 : params[:limit]

    respond_to do |format|
      format.html do
        @events = Analytics::Visitor.all(:limit=>limit, :order=>'updated_at DESC')
        @events = @events.collect {|v| v.events}.flatten.delete_if {|e| e.nil? or e.created_at.nil?}.sort {|a,b| b.created_at <=> a.created_at }
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
