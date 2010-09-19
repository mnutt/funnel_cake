#
# Routes for FunnelCake rails engine
#
Rails.application.routes.draw do

  match 'analytics', :to => "Analytics::Dashboards#overview"

  namespace :analytics do
    resources :events
    
    resources :conversions do
      member do
        get :history
        get :visitors
      end
    end

    resources :states do
      member do
        get :visitors
      end
    end

    resources :ignores
    
    resources :visitors
    
    resources :stats
    
    resources :dashboards do
      collection do
        get :main
        get :cec
        get :diagram
        get :overview
        get :clear_cache
        get :customers
      end
    end
  end

end
