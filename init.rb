require File.dirname(__FILE__) + '/lib/acts_as_funnel_state_machine'
require File.dirname(__FILE__) + '/lib/has_funnel/user_extensions'
require File.dirname(__FILE__) + '/lib/acts_as_funnel_event/funnel_event_extensions'

ActiveRecord::Base.class_eval do
  include ScottBarron::Acts::FunnelStateMachine  
  include FunnelCake::HasFunnel::UserExtensions
  include FunnelCake::ActsAsFunnelEvent::FunnelEventExtensions
end
