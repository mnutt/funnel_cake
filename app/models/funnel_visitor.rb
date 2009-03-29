class FunnelVisitor < ActiveRecord::Base
  # Set up the FunnelEvent model association
  has_many :funnel_events, :class_name=>'FunnelEvent'
  
  # Set up state machine           
  acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false, 
                                :log_transitions=>true,
                                :error_on_invalid_transition=>false
  state :unknown
  self.extend FunnelCake::UserStates
  initialize_states
  
  # Add association for User model
  belongs_to :user, :class_name=>'User', :foreign_key=>:user_id
  
  # include the instance methods
  include FunnelCake::HasFunnel::UserExtensions::InstanceMethods
end
