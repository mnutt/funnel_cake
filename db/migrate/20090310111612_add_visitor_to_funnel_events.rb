class AddVisitorToFunnelEvents < ActiveRecord::Migration
  def self.up
    add_column :funnel_events, :funnel_visitor_id, :integer
  end

  def self.down
    remove_column :funnel_events, :funnel_visitor_id
  end
end
