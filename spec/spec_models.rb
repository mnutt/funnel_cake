require 'spec_helper'

module UserTestStates
  def initialize_states
    state :page_visited, :primary=>true
    funnel_event :view_page do
      transitions :unknown,       :page_visited
      transitions :page_visited,  :page_visited
    end
    funnel_event :start_a do
      transitions :page_visited,  :a_started
    end
    funnel_event :start_b do
      transitions :a_started,     :b_started
    end
  end
end

module Analytics; end
class Analytics::Event
  include MongoMapper::Document
end

class Analytics::Visitor
  include MongoMapper::Document

  timestamps!
  key :key, String
  key :user_id, Integer
  key :state, String
  key :ip, String

  many :events, :class_name=>'Analytics::Event', :dependent=>:destroy, :foreign_key=>:visitor_id
end

class Analytics::Event
  key :to, String
  key :from, String
  key :url, String
  key :name, String
  key :visitor, Analytics::Visitor
  key :referer, String
  key :user_agent, String
  timestamps!
end

# class User < ActiveRecord::Base
#   set_table_name :users
#   has_funnel :class_name=>'Analytics::Event', :foreign_key=>'user_id',
#               :state_module=>'UserTestStates'
# end
