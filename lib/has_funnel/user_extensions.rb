
module FunnelCake
  module HasFunnel

    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def has_funnel(opts={})

          # Set up the Analytics::Visitor model association
          opts[:visitor_class_name] = 'Analytics::Visitor' if opts[:visitor_class_name].nil?
          params = {:class_name=>opts[:visitor_class_name], :dependent=>:destroy}
          params[:foreign_key] = opts[:visitor_foreign_key] unless opts[:visitor_foreign_key].nil?
          has_one :visitor, params

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
          self.visitor.log_funnel_event(event, data) unless self.visitor.nil?
        end

      end
    end

  end
end