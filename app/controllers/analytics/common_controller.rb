class Analytics::CommonController < ApplicationController

  before_filter :setup_funnel_cake_includes
  def setup_funnel_cake_includes
    @javascripts.push 'excanvas'
    @javascripts.push 'funnelcake'
    @javascripts.push 'canviz'
    @javascripts.push 'path'
    @javascripts.push 'x11colors'
    @javascripts.push 'flotr.debug-0.2.0-alpha'
    @stylesheets.push 'funnel_cake'
  end

  helper 'analytics/common'
  include Analytics::CommonHelper

  private

  def add_filter_options(options)
    return options if params[:filter_data].blank?
    data = ActiveSupport::JSON.decode(params[:filter_data])
    data = data.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    options.merge(data)
  end

  def grab_date_range
    if params[:time_period]
      return current_period(params[:time_period].to_i.days)
    elsif !params[:date_range_start].blank? and !params[:date_range_end].blank?
      return params[:date_range_start].to_date..params[:date_range_end].to_date
    end
    return 1.month.ago..0.days.ago
  end

end
