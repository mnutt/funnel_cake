# Funnel Cake

FunnelCake is a rails engine plugin that provides sales funnel tracking functionality.

While there are plenty of web analytics solutions, and many of them offer goal-tracking and even "funnels"... many businesses require a higher-level sales tracking tool.  FunnelCake aims to solve this problem by making it easy to track user "events" or conversion milestones.  It is designed to easily plug into an existing web app, attaching to your User model and overlaying a finite state machine onto your User's actions.  Controllers and views are included to make it easy to visualize conversion rates throughout your sales funnel.

## Usage

FunnelCake is composed of a few parts:

* Rails Plugin code that can be easily mixed into your existing User model and application controllers:
  * A User model directive: `has_funnel`, which provides state_machine and tracking capabilities for your existing user model
  * An ApplicationController directive: `has_visitor_tracking`, which adds a `before_filter` and some utility methods for tracking "visitors" to your site and linking them up to Users when they authenticate
* A core `FunnelCake::Engine` class that contains the logic for calculating conversion rates and other stats
* A rails engine that provides models and controllers for viewing and managing the funnel event data

### Structure

FunnelCake is designed to record "funnel events". These are transitions from any two states in the funnel state machine, for a given user or visitor.  The default class for these events is FunnelEvent, though it can be overridden in the settings (in theory!).  This model is provided as part of the engine, in the /app subdirectory of FunnelCake.

FunnelEvents can belong to either User's and Visitor's.  The plugin is designed to work with your existing User model, by mixing in the required logic when you issue the "has_funnel" directive in your model.  The code is designed to work with any User class name, but it has only been tested extensively with the name "User".

Visitors are similar to users, except that they are unauthenticated visitors to your site.  Often, you will want to start tracking progress in your funnel *before* visitors actually sign up for an account.  Visitors let you do this, because they are tracked by sending a cookie with a unique hash to new visitors.  Then, when a visitor authenticates to your site, the visitor is synced up with a User id... so that funnel calculations are seamless across visitors and users.  The default class name for visitors is FunnelVisitor, and this class is included in the /app engine subdirectory.

### Visualization

FunnelCake comes with a variety of visualization widgets for viewing different aspects of the analytics data.  These include:

* A whole-system FSM diagram, showing all funnel state and transition stats
* "funnel"-style widgets for viewing conversion stats between two specific states
* Historical graphing of conversion stats between two states (in "rate" or "absolute" terms)
* Dynamic table of historical conversion data
* Single-stat widgets for displaying a single-number analytics statistic in a dashboard-friendly large-type format (eg:  "555 New Customers This Month")
* Table of visitors eligible-for/entered-into a given state


#### REST-ful Views

Most of FunnelCake is designed with a RESTful architecture.  Thus, it exposes useful views for many of the analytics components, such as:

* `/conversions` - an index view of all primary conversions stats
* `/conversions/state_one-state_two` - a detailed view of the conversion stats from `state_one` to `state_two`
* `/states` - an index view of all states
* `/states/state_one` - a detailed view of `state_one`
* `/stats/entered_state_count?state=state_one` - a view of the `entered_state_count` statistic for `state_one`

In addition, most of the `:show` actions for these RESTful views also render to JSON, which provides data for the various FunnelCake dashboard widgets.

#### The Overview Page

Because FunnelCake uses a FSM model for funnel tracking, a FSM-style node graph seemed an appropriate choice for visualizing the entire funnel.  This is especially useful if you have a complex sales process (which might be a problem of its own!!)  The overview also provides a more simplistic, traditional "funnel" view, with conversion rates calculated for all of the states that are marked as `:primary=>true`.

#### Custom Dashboards

FunnelCake is designed to allow developers to easily create new custom dashboards to serve their own business needs.  In includes a handful of simple partials that can be added to any view, allowing the developer to drop in a few lines of Rails ERB-code to place the FunnelCake dashboard widgets that show the data that they are interested in.

The graph visualization is done using [GraphViz](http://www.graphviz.org/), and the very handy javascript [Canviz](http://code.google.com/p/canviz) project.  The other canvas funnel visualization is my own concoction, using the excellent [ExCanvas](http://excanvas.sourceforge.net) project.  Graphing is done using the excellent [Flotr Javascript Plotting Library](http://solutoire.com/flotr/).

Here is an example of sales funnel visualization using FunnelCake:

![Example Funnel Visualization](http://github.com/jkrall/funnel_cake/raw/master/doc/example_funnel.png)

## Configuration

Configuration of FunnelCake is fairly simple.  First of all, you need to be on Rails 3.0.

### Installation

Simply add the following to your Gemfile:

  gem 'funnel_cake'

Rails serves FunnelCake's static assets automatically.  In production environments you'll want to copy them to your public/ directory so that they can be served by your webserver.

### User Model Setup

To install FunnelCake into your User model, simply add the following line:

	has_funnel

There are a few options that you can supply to has_funnel, if you decide to name your models differently... but they are not documented here (yet).

In addition, you will need to create a file that specifies the funnel event states for your application.  The default location and name for this file is:  lib/funnel_cake/user_states.rb.  However, you can use a different file location by supplying `:state_module=>'SomeOtherModule::MyCustomStates'` to the `has_funnel` method.

FunnelCake::UserStates is a simple mixin-module that acts as a container for your states.  It contains a single method, initialize_states, that does all of the setup.  Here's an example config file, for the funnel depicted above:

	module FunnelCake::UserStates
	  def initialize_states

	    funnel_state :page_visited, :primary=>true
	    funnel_state :ccproc_report

	    funnel_state :auction_form_visited, :primary=>true
	    funnel_state :signup_step_2, :primary=>true
	    funnel_state :signup_step_3
	    funnel_state :signup_step_3_previous_statement
	    funnel_state :signup_step_4

	    funnel_state :auction_started, :primary=>true
	    funnel_state :auction_closed, :primary=>true
	    funnel_state :auction_bid_selected, :primary=>true
	    funnel_state :auction_completed
	    funnel_state :auction_booked, :primary=>true

	    funnel_event :view_page do
	      transitions :unknown,                     :page_visited
	      transitions :page_visited,                :page_visited
	    end
	    funnel_event :create_ccproc_report do
	      transitions :page_visited,                :ccproc_report
	    end

	    funnel_event :auction_form_visit do
	      transitions :page_visited,                :auction_form_visited
	      transitions :ccproc_report,               :auction_form_visited
	    end
	    funnel_event :signup_step_2 do
	      transitions :auction_form_visited,        :signup_step_2
	    end
	    funnel_event :signup_step_3 do
	      transitions :signup_step_2,               :signup_step_3
	    end
	    funnel_event :signup_step_3_previous_statement do
	      transitions :signup_step_3,               :signup_step_3_previous_statement
	    end
	    funnel_event :signup_step_4 do
	      transitions :signup_step_3_previous_statement,          :signup_step_4
	      transitions :signup_step_3,               :signup_step_4
	    end

	    funnel_event :start_auction do
	      transitions :signup_step_4,               :auction_started
	    end

	    funnel_event :close_auction do
	      transitions :auction_started,             :auction_closed
	    end
	    funnel_event :auction_choosebid_email do
	      transitions :auction_closed,              :auction_choosebid_emailed
	    end
	    funnel_event :upload_statement do
	      transitions :auction_closed,              :auction_uploaded_statement
	      transitions :auction_choosebid_emailed,   :auction_uploaded_statement
	    end
	    funnel_event :savings_analysis_ready_email do
	      transitions :auction_uploaded_statement,  :savings_analysis_ready
	    end
	    funnel_event :select_bid do
	      transitions :auction_closed,              :auction_bid_selected
	      transitions :auction_choosebid_emailed,   :auction_bid_selected
	      transitions :auction_uploaded_statement,  :auction_bid_selected
	      transitions :savings_analysis_ready,      :auction_bid_selected
	    end

	    funnel_event :auction_finish_email do
	      transitions :auction_bid_selected,        :auction_finish_emailed
	    end
	    funnel_event :complete_auction do
	      transitions :auction_bid_selected,        :auction_completed
	      transitions :auction_finish_emailed,      :auction_completed
	    end
	    funnel_event :book_auction do
	      transitions :auction_finish_emailed,        :auction_booked
	      transitions :auction_bid_selected,        :auction_booked
	      transitions :auction_completed,           :auction_booked
	    end

	  end
	end

Pay attention to the naming conventions used here.  While the plugin does not care about the names you use... it is easy to get confused between "events" and "states".  When triggering funnel events in your application code, you will always use the `funnel_event` names.

Finally, the `state xxxxx, :primary=>true` lines are only required so that you can tell FunnelCake which states are important for calculating overall conversion rates.  These states will be highlighted in the visualization, and the conversion rates are automatically displayed.  (FunnelCake can calculate conversions between any two states... but it gets complicated if you have lots of branching, so it is best to keep the `:primary` states to those which are true milestones that all users pass through)

### ApplicationController Setup

To install FunnelCake's visitor tracking into your ApplicationController, add the following:

	has_visitor_tracking :cookie_name=>:transfs_ut

The `:cookie_name` argument is what it sounds like.  This is the name of the cookie that FunnelCake will use to track anonymous visitors on your site.

### Triggering Funnel Events in your Application

To trigger a funnel event in your app... there are a few utility methods available:

	log_funnel_event(event, data)
	User.log_funnel_event(event, data)
	log_funnel_page_visit()
	sync_funnel_visitor

`log_funnel_event(event, data)` records a generic funnel event.  You can supply optional data, though the only data key that is currently recognized/stored is :url.

`User.log_funnel_event(event, data)` is an exact copy of the above controller method.  In fact, when you call `log_funnel_event()` on the controller, it simply determines if you have a valid user or valid visitor, and sends `log_funnel_event()` on to the model.  Thus, if you have access to a user in a non-controller context (in a Workling task, for instance)... you can still log funnel events by calling the User method directly.  The same is true for the FunnelVisitor model, however there are no obvious reasons why you would want to call this method directly on a visitor instance.

`log_funnel_page_visit` does what it sounds like.  It records a funnel event for the `:view_page event`.  NOTE: if you want to use this method, you need to have a `:view_page` event in your FSM!  This method just calls `log_funnel_event` under the hood.

`sync_funnel_visitor` is a specific method that links up an unauthorized visitor to an authorized user.  This method should be called immediately after you have authenticated a user, usually in your `SessionsController#create` method.

## Credits

FunnelCake was created, and is maintained by [Joshua Krall](http://github.com/jkrall).  More info at [Transparent Development](http://transfs.com/devblog), the [TransFS.com](http://transfs.com) development blog.

