
ActiveRecord::Base.class_eval do
  include FunnelCake::ActsAsFunnelStateMachine
  include FunnelCake::HasFunnel::UserExtensions
end

ActionController::Base.class_eval do
  include FunnelCake::HasVisitorTracking::ControllerExtensions
end
