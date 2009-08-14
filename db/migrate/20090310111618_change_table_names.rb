class ChangeTableNames < ActiveRecord::Migration
  def self.up
    rename_table :funnel_events, :funnelcake_events
    rename_table :funnel_visitors, :funnelcake_visitors
    rename_table :funnel_ignores, :funnelcake_ignores
  end

  def self.down
    rename_table :funnelcake_events, :funnel_events
    rename_table :funnelcake_visitors, :funnel_visitors
    rename_table :funnelcake_ignores, :funnel_ignores
  end
end
