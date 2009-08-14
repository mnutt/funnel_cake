class Analytics::Event < ActiveRecord::Base
  set_table_name :funnelcake_events

  # Add visitor association
  belongs_to :visitor, :class_name=>'Analytics::Visitor', :foreign_key=>:visitor_id
end
