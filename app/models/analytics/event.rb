class Analytics::Event
  include MongoMapper::EmbeddedDocument

  key :to, String
  key :from, String
  key :url, String
  key :name, String
  key :referer, String
  key :user_agent, String

  # timestamps!
  key :created_at, Time
  def save
    self.created_at = Time.now if created_at.nil?
    super
  end

  # belongs_to :visitor, :class_name=>'Analytics::Visitor', :foreign_key=>'visitor_id'
  # named_scope :sorted_by_date, :order=>'created_at DESC'
  # named_scope :sorted, :order=>'id DESC'

end
