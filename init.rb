require File.dirname(__FILE__) + '/lib/funnel_cake/data_hash'
require File.dirname(__FILE__) + '/lib/funnel_cake/state_period_helpers'
require File.dirname(__FILE__) + '/lib/funnel_cake/engine'
require File.dirname(__FILE__) + '/lib/funnel_cake/random_id'
require File.dirname(__FILE__) + '/lib/acts_as_funnel_state_machine'
require File.dirname(__FILE__) + '/lib/has_funnel/user_extensions'
require File.dirname(__FILE__) + '/lib/has_visitor_tracking/controller_extensions'

ActiveRecord::Base.class_eval do
  include ScottBarron::Acts::FunnelStateMachine
  include FunnelCake::HasFunnel::UserExtensions
end

ActionController::Base.class_eval do
  include FunnelCake::HasVisitorTracking::ControllerExtensions
end
