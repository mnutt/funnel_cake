ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do |t|
    t.column :email, :string
    t.timestamps    
  end
  
  create_table :funnel_events, :force => true do |t|
    t.string :to
    t.string :from
    t.integer :user_id
    t.integer :funnel_visitor_id
    t.string :url
    t.string :name
    t.timestamps    
  end
  
  create_table :funnel_visitors, :force => true do |t|
   t.string :key
   t.string :state   
   t.integer :user_id
  end
end
