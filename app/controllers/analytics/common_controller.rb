class Analytics::CommonController < ApplicationController
  unloadable if RAILS_ENV=='development'

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
    data = {}
    if params[:compare]
      compare = ActiveSupport::JSON.decode(params[:compare])
      data = {:compare=>compare.collect {|cur_filter_data| process_filter_data(cur_filter_data)}}
    end
    data = process_filter_data(ActiveSupport::JSON.decode(params[:filter_data])) if params[:filter_data]
    options.merge(data)
  end

  def process_filter_data(data)
    data = data.inject({}) do |h, (k, v)|
      v = convert_hash_values_to_regexes(v) if v.is_a?(Hash)
      h[k.to_sym] = v unless v.blank?
      h
    end
    data
  end

  def convert_hash_values_to_regexes(hash)
    hash.inject({}) do |h, (k,v)|
      h[k.to_sym] = v[/^\/.*\/$/].blank? ? v : /#{v[1..-2]}/ unless v.blank?
      h
    end
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
