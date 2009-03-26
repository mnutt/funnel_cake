#
# Routes for FunnelCake rails engine
# 
ActionController::Routing::Routes.draw do |map|

  map.resources :funnel_events, {:collection=>{:diagram=>:any}}
  
end