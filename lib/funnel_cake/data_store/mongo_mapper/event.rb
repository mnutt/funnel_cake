require 'mongo_mapper'

module FunnelCake
  module DataStore
    module MongoMapper
      module Event

        def self.included(base)
          base.class_eval do
            include ::MongoMapper::EmbeddedDocument

            key :to, String
            key :from, String
            key :url, String
            key :name, String
            key :referer, String
            key :user_agent, String

            #timestamps!
            key :created_at, Time

            def self.create(attrs={})
              _new = new(attrs)
              _new.update_timestamp!
              _new
            end

          end
        end

        def update_timestamp!
          self.created_at = Time.now
        end

        def visitor
          _root_document
        end

      end
    end
  end
end
