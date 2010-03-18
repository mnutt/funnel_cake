class Analytics::Event
  include MongoMapper::EmbeddedDocument

  key :to, String
  key :from, String
  key :url, String
  key :name, String
  key :referer, String
  key :user_agent, String

  #timestamps!
  key :created_at, Time
  def update_timestamp!
    self.created_at = Time.now
  end

  def self.create(attrs={})
    _new = new(attrs)
    _new.update_timestamp!
    _new
  end

  def visitor
    _root_document
  end

  include Comparable
  def <=>(other)
    return 0 if created_at.nil? or other.created_at.nil?
    created_at <=> other.created_at
  end
end
