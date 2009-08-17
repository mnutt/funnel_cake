module Analytics::StagesHelper

  def state_graph_visitors(state, date_range)
    opts = {:date_range=>date_range, :attrition_period=>1.month}
    next_state = next_state_from(state)
    state_pair_visitors = FunnelCake::Engine.find_by_state_pair(state, next_state, opts)
    state_pair_visitors = state_pair_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    starting_state_visitors = FunnelCake::Engine.find_by_starting_state(state, opts).to_a | state_pair_visitors
    starting_state_visitors = starting_state_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    [starting_state_visitors, state_pair_visitors]
  end


end