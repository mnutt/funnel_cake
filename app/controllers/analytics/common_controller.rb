class Analytics::CommonController < ApplicationController

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

  private

  def add_filter_options(options)
    return options if params[:filter_data].blank?
    data = ActiveSupport::JSON.decode(params[:filter_data])
    data = data.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
    options.merge(data)
  end

end
