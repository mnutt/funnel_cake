class AddStatsToFunnel < ActiveRecord::Migration
  def self.up
    add_column :funnel_visitors, :ip, :string
    add_column :funnel_events, :referer, :string
  end

  def self.down
    remove_column :funnel_visitors, :ip
    remove_column :funnel_events, :referer    
  end
end
