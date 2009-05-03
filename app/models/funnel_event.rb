class FunnelEvent < ActiveRecord::Base
  # Add visitor association
  belongs_to :funnel_visitor, :class_name=>'FunnelVisitor', :foreign_key=>:funnel_visitor_id            
end
