class CreateFunnelVisitors < ActiveRecord::Migration
  def self.up
    create_table :funnel_visitors do |t|
      t.string :key
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :funnel_visitors
  end
end
