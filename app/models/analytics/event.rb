class Analytics::Event
  include MongoMapper::Document

  key :to, String
  key :from, String
  key :url, String
  key :name, String
  key :visitor, Analytics::Visitor
  key :referer, String
  key :user_agent, String
  timestamps!

  # named_scope :sorted_by_date, :order=>'created_at DESC'
  # named_scope :sorted, :order=>'id DESC'

end
