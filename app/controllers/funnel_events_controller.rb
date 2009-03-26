class FunnelEventsController < ApplicationController

  def setup_includes
    super
    @stylesheets = ['admin']
  end

  def index
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
