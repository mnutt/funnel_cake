class AddUaToFunnel < ActiveRecord::Migration
  def self.up
    add_column :funnel_events, :user_agent, :string
  end

  def self.down
    remove_column :funnel_events, :user_agent
  end
end
