
module FunnelCake
  module HasFunnel
    
    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def has_funnel(opts={})
          
          # Set up the FunnelEvent model association
          params = {:class_name=>'FunnelEvent'}
          params[:class_name] = opts[:class_name] unless opts[:class_name].nil?
          params[:foreign_key] = opts[:foreign_key] unless opts[:foreign_key].nil?
          has_many :funnel_events, params
          
          # Set up the state machine, and give it an initial unknown state
          acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false, 
                                                           :log_transitions=>true,
                                                           :error_on_invalid_transition=>false
          state :unknown
          
          # include the User state machine module
          opts[:state_module] = 'FunnelCake::UserStates' if opts[:state_module].nil?
          self.extend(opts[:state_module].constantize)
          initialize_states
          
          # store the current user class name, for the meta stuff below
          user_class_name = self.to_s          

          #
          # Set up the Visitor class, using the User model settings
          #
          opts[:visitor_class_name] = 'FunnelVisitor' if opts[:visitor_class_name].nil?
          opts[:visitor_class_name].constantize.module_eval do

            # Set up the FunnelEvent model association
            params = {:class_name=>'FunnelEvent'}
            params[:class_name] = opts[:class_name] unless opts[:class_name].nil?
            params[:foreign_key] = opts[:foreign_key] unless opts[:foreign_key].nil?
            has_many :funnel_events, params
            
            # Set up state machine           
            acts_as_funnel_state_machine :initial=>:unknown, :validate_on_transitions=>false, 
                                                             :log_transitions=>true,
                                                             :error_on_invalid_transition=>false
            state :unknown
            self.extend(opts[:state_module].constantize)
            initialize_states
            
            # Add association for User model
            belongs_to :user, :class_name=>user_class_name, :foreign_key=>:user_id
            
            # include the instance methods
            include FunnelCake::HasFunnel::UserExtensions::InstanceMethods
          end
          
          # Set up the FunnelVisitor model association
          params = {:class_name=>opts[:visitor_class_name]}
          params[:foreign_key] = opts[:visitor_foreign_key] unless opts[:visitor_foreign_key].nil?
          has_many :visitors, params

          #
          # Set up the Funnel Events class
          #
          params = {:class_name=>'FunnelEvent'}
          params[:class_name] = opts[:class_name] unless opts[:class_name].nil?
          params[:class_name].constantize.module_eval do
            # Add user association
            belongs_to :user, :class_name=>user_class_name, :foreign_key=>:user_id
            
            # Add visitor association
            belongs_to :funnel_visitor, :class_name=>opts[:visitor_class_name], :foreign_key=>:funnel_visitor_id            
          end          
          
          # include the instance methods
          include FunnelCake::HasFunnel::UserExtensions::InstanceMethods
        end
        
        # Wrap the state machine event, so we can add a funnel_ prefix
        def funnel_event(name, &block)
          funnel_name = "funnel_#{name}".to_sym
          event(funnel_name, block)
        end
        

        
      end
      
      module InstanceMethods
        
        # Create a FunnelEvent, as a callback to a state_machine transition
        def log_transition(from, to, event, data, opts)  
          self.funnel_events.create( :from=>from.to_s, :to=>to.to_s, 
                                    :url=>data[:url], :name=>event.to_s)
        end
        
        # Utility method for logging funnel events from within application code
        # (This is probably how most funnel events will be triggered)
        # - First check if the event is legal... if not, log an error I guess!
        # - Second, send() the event method with the accompanying data
        def log_funnel_event(event, data={})
          unless self.valid_events.include?(event.to_sym)
            logger.debug "#{self.class.to_s} couldn't log FunnelCake event: #{event} This event is not valid for state: #{self.current_state}" 
            return
          end
          self.send(event.to_s+"!", data)
        end
        
      end
    end
    
  end
end