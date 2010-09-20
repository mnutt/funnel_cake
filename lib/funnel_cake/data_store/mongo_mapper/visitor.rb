require 'mongo_mapper'

MongoMapper.database = 'funnel_cake'

module FunnelCake
  module DataStore
    module MongoMapper
      module Visitor

        def self.included(base)
          base.class_eval do
            include ::MongoMapper::Document
            include FunnelCake::HasFunnel::UserExtensions

            timestamps!
            key :user_id, Integer
            key :key, String
            key :state, String
            key :ip, String

            ensure_index :created_at
            ensure_index :updated_at
            ensure_index :user_id
            ensure_index :key
            ensure_index :state
            ensure_index :ip
            ensure_index 'events.to'
            ensure_index 'events.from'
            ensure_index 'events.name'
            ensure_index 'events.referer'
            ensure_index 'events.user_agent'
            ensure_index 'events.url'
            ensure_index 'events.created_at'

            # Set up the Analytics::Event model association
            many :events, :class_name=>FunnelCake.event_class.to_s, :dependent=>:destroy, :foreign_key=>:visitor_id
          end
        end

        # Add association for User model, manually b/c the User model is AR
        def user; User.find_by_id(user_id); end
        def user=(u); self.user_id = u.id; end

        def to_funnelcake
          attrs = attributes.clone
          attrs.merge(user.to_funnelcake) if user and user.respond_to?(:to_funnelcake)
          attrs[:recent_event_date] = events.last.created_at.to_s(:short)
          attrs[:id] = attrs.delete('_id')
          attrs
        end

        def update_statistics(data)
          increment_statistic('referers', data[:referer])
          increment_statistic('user_agents', data[:user_agent])
          increment_statistic('landing_pages', data[:url])
        end

        def increment_statistic(collection, stat)
          ::MongoMapper.database.collection("analytics.statistics.#{collection}").update({'_id'=>stat}, {'$inc'=>{'value.count'=>1}})
        end
      end
    end
  end
end
