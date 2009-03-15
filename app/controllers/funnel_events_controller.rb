
class FunnelEventsController < ApplicationController

  def setup_includes
    super
    @stylesheets = ['admin']
  end

  def index
    @javascripts.push 'canviz'
    @javascripts.push 'path'
    @javascripts.push 'x11colors'    
  end
    
end