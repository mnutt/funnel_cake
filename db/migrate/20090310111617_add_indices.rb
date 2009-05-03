class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :funnel_events, :funnel_visitor_id
    add_index :funnel_events, :to
    add_index :funnel_events, :from
    
    add_index :funnel_visitors, :user_id
    add_index :funnel_visitors, :state
    add_index :funnel_visitors, :key
  end

  def self.down
    remove_index :funnel_events, :funnel_visitor_id
    remove_index :funnel_events, :to
    remove_index :funnel_events, :from
    
    remove_index :funnel_visitors, :user_id
    remove_index :funnel_visitors, :state
    remove_index :funnel_visitors, :key
  end
end
