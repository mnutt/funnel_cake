module FunnelCake
  module HasUserTracking
  
    module ControllerExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end

      module ClassMethods
        def has_user_tracking(opts = {})

          before_filter :track_visitor_as_user
                    
          # include the instance methods
          include FunnelCake::HasUserTracking::ControllerExtensions::InstanceMethods
        end
        
        
      end

      module InstanceMethods
        
        def track_visitor_as_user
          if cookies[:transfs_ut].nil?
            cookies[:transfs_ut] = {
              :value => RandomId.generate(50)
            }
          end
        end
        
      end
    end  
  
  end
end