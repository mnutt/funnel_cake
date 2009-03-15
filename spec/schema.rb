ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do |t|
    t.column :email, :string
    t.timestamps    
  end
  
  create_table :funnel_events, :force => true do |t|
    t.string :to
    t.string :from
    t.integer :user_id
    t.string :url
    t.string :name
    t.timestamps    
  end
end
