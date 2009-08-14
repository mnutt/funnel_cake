class Analytics::EventsController < ApplicationController

  before_filter :setup_funnel_cake_includes
  def setup_funnel_cake_includes
    @javascripts.push 'excanvas'
    @javascripts.push 'funnel_chart'
    @javascripts.push 'canviz'
    @javascripts.push 'path'
    @javascripts.push 'x11colors'
    @javascripts.push 'flotr-0.2.0-alpha'
    @stylesheets.push 'funnel_cake'
  end

  def index
    limit = params[:limit].nil? ? 25 : params[:limit]

    respond_to do |format|
      format.html do
        @events = Analytics::Event.find(:all, :limit=>limit, :include=>[:user, :visitor], :order=>'created_at DESC')
      end
      format.js do
        timestamp = params[:timestamp].to_datetime
        @events = Analytics::Event.find(:all, :limit=>limit, :include=>[:user, :visitor],
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
    respond_to do |format|
      format.js { render }
    end
  end

  def state_graph
    @time_period = params[:days].to_i.days
    @state = params[:state]
    respond_to do |format|
      format.js { render }
    end
  end

  def funnel_stage
    date_range = params[:date_range_start].to_i.days.ago..params[:date_range_end].to_i.days.ago
    @state = params[:state]
    @next_state = params[:next_state]
    @stats = FunnelCake::Engine.conversion_stats(@state, @next_state, {:date_range=>date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.js { render }
    end
  end


  def overview
  end

  def conversions
  end

  def conversions_detail
    @time_period = params[:days].to_i
    @state = params[:state]
    render :layout=>false
  end

end
