require 'mongo_mapper'

module FunnelCake
  module DataStore
    module MongoMapper
      module Ignore

        def self.included(base)
          base.class_eval do
            include ::MongoMapper::Document

            key :ip, String
            key :name, String
            timestamps!
          end
        end

      end
    end
  end
end