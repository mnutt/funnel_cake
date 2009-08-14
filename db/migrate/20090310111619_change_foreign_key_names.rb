class ChangeForeignKeyNames < ActiveRecord::Migration
  def self.up
    rename_column :funnelcake_events, :funnel_visitor_id, :visitor_id
  end

  def self.down
    rename_column :funnelcake_events, :visitor_id, :funnel_visitor_id
  end
end
