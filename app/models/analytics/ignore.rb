class Analytics::Ignore
  include MongoMapper::Document
  key :ip, String
  key :name, String
  timestamps!
end
