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

