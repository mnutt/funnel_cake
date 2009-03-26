class AddStateToFunnelVisitor < ActiveRecord::Migration
  def self.up
    add_column :funnel_visitors, :state, :string, :default=>'unknown'
  end

  def self.down
    remove_column :funnel_visitors, :state
  end
end
