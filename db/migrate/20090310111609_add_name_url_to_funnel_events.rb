class CreateFunnelEvents < ActiveRecord::Migration
  def self.up
    add_column :funnel_events, :url, :string
    add_column :funnel_events, :name, :string    
  end

  def self.down
    remove_column :funnel_events, :url
    remove_column :funnel_events, :name    
  end
end
