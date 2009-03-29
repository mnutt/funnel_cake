class CreateFunnelIgnores < ActiveRecord::Migration
  def self.up
    create_table :funnel_ignores do |t|
      t.string :ip
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :funnel_ignores
  end
end
