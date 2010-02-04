class Analytics::Event
  include MongoMapper::Document

  key :to, String
  key :from, String
  key :url, String
  key :name, String
  key :visitor_id, ObjectId
  key :referer, String
  key :user_agent, String
  timestamps!

  belongs_to :visitor, :class_name=>'Analytics::Visitor', :foreign_key=>'visitor_id'

  # named_scope :sorted_by_date, :order=>'created_at DESC'
  # named_scope :sorted, :order=>'id DESC'

end
