module FunnelCake
  module ActsAsFunnelEvent
  
    module FunnelEventExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def acts_as_funnel_event(opts = {})

          params = {:class_name => 'User'}
          params[:class_name] = opts[:class_name] unless opts[:class_name].nil?
          params[:foreign_key] = opts[:foreign_key] unless opts[:foreign_key].nil?
          has_one :user, params
          
          # include the instance methods
          include FunnelCake::ActsAsFunnelEvent::FunnelEventExtensions::InstanceMethods
        end
        
        
      end

      module InstanceMethods
        
        
      end
    end  
  
  end
end