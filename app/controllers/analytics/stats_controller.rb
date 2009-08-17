class Analytics::StatsController < ApplicationController

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

  def show
    unless params[:date_range_start].blank? or params[:date_range_end].blank?
      @date_range = params[:date_range_start].to_date..params[:date_range_end].to_date
    else
      @date_range = 1.month.ago..0.days.ago
    end
    @stat = params[:id]

    if @stat == 'entered_state_count'
      state = params[:state].to_sym
      @title = state.to_s.titleize
      @value = FunnelCake::Engine.find_by_ending_state(state, {:date_range=>@date_range}).length
      @stat_name = "#{@stat}-#{state}"
    else
      @title = 'Unknown'
      @value = 0
      @stat_name = ''
    end

    respond_to do |format|
      format.html
      format.js
    end
  end




end
