class Analytics::StagesController < ApplicationController

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

  before_filter :load_state_from_id, :only=>[:show, :stats, :detail, :visitors]
  def load_state_from_id
    @state = params[:id].sub(/-.*/,'')
    @next_state = params[:id].sub(/[^-]*-/,'')
  end

  def index
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def stats
    @date_range = params[:date_range_start].to_date..params[:date_range_end].to_date
    @stats = FunnelCake::Engine.conversion_stats(@state, @next_state, {:date_range=>@date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.js { render }
    end
  end

  def detail
    @date_range = params[:date_range_start].to_date..params[:date_range_end].to_date
    respond_to do |format|
      format.html { render :layout=>false }
    end
  end

  def visitors
    @date_range = params[:date_range_start].to_date..params[:date_range_end].to_date
    respond_to do |format|
      format.html do
        render :partial=>'visitors',
                :locals=>{:state=>@state, :next_state=>@next_state, :date_range=>@date_range}
      end
    end
  end




end
