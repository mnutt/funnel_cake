class Analytics::StatesController < ApplicationController

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

  # def index
  #   respond_to do |format|
  #     format.html # show.html.erb
  #   end
  # end
  #
  # def show
  #   respond_to do |format|
  #     format.html # show.html.erb
  #   end
  # end

  def graph_data
    @time_period = params[:time_period].to_i.days
    @state = params[:id]
    respond_to do |format|
      format.js { render }
    end
  end




end
