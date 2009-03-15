class CreateFunnelEvents < ActiveRecord::Migration
  def self.up
    create_table :funnel_events do |t|
      t.string :to
      t.string :from
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :funnel_events
  end
end
