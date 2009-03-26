class FunnelEventsController < ApplicationController

  def index
    limit = params[:limit].nil? ? 25 : params[:limit]

    respond_to do |format|
      format.html do
        @funnel_events = FunnelEvent.find(:all, :limit=>limit, :include=>[:user, :funnel_visitor], :order=>'created_at DESC')
      end
      format.js do 
        timestamp = params[:timestamp].to_datetime
        @funnel_events = FunnelEvent.find(:all, :limit=>limit, :include=>[:user, :funnel_visitor], 
                                                :order=>'created_at DESC', :conditions=>['created_at > ?',timestamp])
      end
    end
  end

  def diagram
    @javascripts.push 'excanvas'
    @javascripts.push 'funnel_chart'    
    @javascripts.push 'canviz'
    @javascripts.push 'path'
    @javascripts.push 'x11colors'    
  end
    
  def xdot_callback
    @daterange = params[:start_days_ago].to_i.days.ago .. params[:end_days_ago].to_i.days.ago
    respond_to do |format|
      format.js { render }
    end
  end

   
end
