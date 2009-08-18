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

  helper 'analytics/common'
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
    respond_to do |format|
      format.js { render }
    end
  end

  def overview
  end

end
