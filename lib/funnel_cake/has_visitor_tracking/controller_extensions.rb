module FunnelCake
  module HasVisitorTracking

    module ControllerExtensions

      def self.included( recipient )
        recipient.extend( FunnelCake::HasVisitorTracking::ControllerExtensions::ClassMethods )
      end

      module ClassMethods
        def has_visitor_tracking(opts = {})
          opts[:cookie_name] = 'visitor_tracker' if opts[:cookie_name].nil?
          write_inheritable_attribute :cookie_name, opts[:cookie_name]

          # set up a callback to prefilter visitors and get them registered
          before_filter :track_visitor

          # include the instance methods
          include FunnelCake::HasVisitorTracking::ControllerExtensions::InstanceMethods
        end
      end

      module InstanceMethods

        protected

        # This is a before_filter callback for registering new visitors
        # - admin users are ignored
        def track_visitor
          return if ignore_funnel_tracking?
          register_funnel_visitor unless visitor_registered?
        end

        # Workhorse utility method for logging funnel events
        # (This is probably how MOST funnel events will be triggered)
        # - checks if we are an admin visitor first
        # - sends the funnel event msg to the current user, if we're logged in
        #   - sets the url, referer, ua data automatically using the request
        # - otherwise, sends it to the current visitor
        # - if there is no valid current visitor, register one
        # - finally... logs an error if we have no current visitor (because that shouldn't happen!)
        def log_funnel_event(event, data={})
          return if ignore_funnel_tracking?
          register_funnel_visitor if current_visitor.nil?
          unless current_visitor.nil?
            data.reverse_merge!({
              :url=>request.request_uri,
              :referer=>request.referer,
              :user_agent=>request.env["HTTP_USER_AGENT"].to_s
            })
            current_visitor.log_funnel_event(event, data)
            return
          end
          logger.info "Couldn't Log FunnelCake Event: #{event}  No Analytics::Visitor found!"
        end

        # Utility method for logging a page visit
        def log_funnel_page_visit
          log_funnel_event(:view_page)
        end

        # Utility method for syncing the current visitor to the current user
        # (This should be called when a user logs in!)
        # - Bails out if not logged in
        # - otherwise, sets the .user of the current_visitor
        def sync_funnel_visitor
          return unless FunnelCake.enabled?

          if not logged_in?
            logger.info "Couldn't sync Analytics::Visitor to nil User"
            return
          end
          if current_visitor.nil?
            logger.info "Couldn't sync nil Analytics::Visitor to current User: #{current_user.inspect}"
            return
          end
          current_visitor.user_id = current_user.id
          current_visitor.save
        end

        private

        # should we ignore this visitor?
        def ignore_funnel_tracking?
          return true unless FunnelCake.enabled?

          # check user-overrideable methods
          return true if respond_to?(:ignore_funnel_visitor?) and ignore_funnel_visitor?

          # ignore search engine bots
          return true if request.env["HTTP_USER_AGENT"] and request.env["HTTP_USER_AGENT"][/Googlebot|msnbot|Yahoo|Baidu|Teoma/]
          return true if funnel_browser_is_bot?

          # check funnel-ignore list
          return true unless Analytics::Ignore.find_by_ip(request.remote_ip.to_s).nil?

          return false
        end

        # Is the current visitor registered?  We check the cookie state to find out
        def visitor_registered?
          cookies[self.class.read_inheritable_attribute(:cookie_name)].nil? == false
        end

        # Register the current visitor (without checking anything first, just do it)
        # - We create a new Analytics::Visitor here, using a new random hex key
        # - Set the cookie value for this visitor
        def register_funnel_visitor
          @current_visitor = FunnelCake.engine.visitor_class.create(
                              :ip=>request.remote_ip.to_s
                              )
          @current_visitor.user_id = current_user.id if logged_in?
          @current_visitor.save
          cookies[self.class.read_inheritable_attribute(:cookie_name)] = {
            :value => @current_visitor.id,
            :expires => 1.year.from_now
          }
        end

        # returns the current Analytics::Visitor object, using the visitor's cookie
        def current_visitor
          return @current_visitor unless @current_visitor.nil?

          # Check if we're logged in first, set the current_visitor from the current_user
          if logged_in?
            @current_visitor = current_user.visitor
          end

          # If we are not logged in, or if the current_user has no visitor,
          # then try to find the visitor by the cookie key
          if @current_visitor.nil?
            cookie = cookies[self.class.read_inheritable_attribute(:cookie_name)].gsub(/[^0-9a-f]/,'')
            if cookie
              if cookie.length > '000000000000000000000000'.length
                @current_visitor = FunnelCake.engine.visitor_class.find_by_key(cookie)
                cookies[self.class.read_inheritable_attribute(:cookie_name)] = {
                  :value => @current_visitor.id,
                  :expires => 1.year.from_now
                } if @current_visitor
              else
                @current_visitor = FunnelCake.engine.visitor_class.find(cookie)
              end
            end
          end

          return @current_visitor
        end


        def funnel_browser_name
          @funnel_browser_name ||= begin
            ua = request.env['HTTP_USER_AGENT'] || ''
            ua.downcase!

            robots = /Googlebot|msnbot|Yahoo|Baidu|Teoma|robot|trada|scoutjet|crawl|tagoobot/i
            if ua[robots]
              'robot'
            elsif ua.index('msie') && ua.length>4 && !ua.index('opera') && !ua.index('webtv')
              'ie'+ua[ua.index('msie')+5].chr
            elsif ua.index('gecko/')
              'gecko'
            elsif ua.index('opera')
              'opera'
            elsif ua.index('konqueror')
              'konqueror'
            elsif ua.index('applewebkit/')
              'safari'
            elsif ua.index('mozilla/')
              'gecko'
            else
              'other'
            end
          end
        end

        def funnel_browser_is_bot?
          return true if ['other', 'robot'].include?(funnel_browser_name)
          false
        end

      end
    end

  end
end
