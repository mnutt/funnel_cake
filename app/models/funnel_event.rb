class FunnelEvent < ActiveRecord::Base
  # Add user association
  belongs_to :user, :class_name=>'User', :foreign_key=>:user_id
  
  # Add visitor association
  belongs_to :funnel_visitor, :class_name=>'FunnelVisitor', :foreign_key=>:funnel_visitor_id            
end
