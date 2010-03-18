
module FunnelCake
  module HasFunnel

    module UserExtensions
      def self.included( recipient )
        recipient.extend( FunnelCake::HasFunnel::UserExtensions::ClassMethods )
      end

      module ClassMethods
        def has_funnel(opts={})

          # include the instance methods
          include FunnelCake::HasFunnel::UserExtensions::InstanceMethods
        end
      end

      module InstanceMethods

        # Utility method for logging funnel events from within application code
        # (This is probably how most funnel events will be triggered)
        # - First check if the event is legal... if not, log an error I guess!
        # - Second, send() the event method with the accompanying data
        def log_funnel_event(event, data={})
          self.visitor.log_funnel_event(event, data) if self.visitor and FunnelCake.enabled?
        end

        def visitor
          Analytics::Visitor.find_by_user_id(id) if FunnelCake.enabled?
        end

      end
    end

  end
end
