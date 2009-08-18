module Analytics::StagesHelper

  def state_graph_visitors(state, opts)
    next_state = next_state_from(state)

    state_pair_visitors = FunnelCake::Engine.find_by_state_pair(state, next_state, opts)
    starting_state_visitors = FunnelCake::Engine.find_by_starting_state(state, opts).to_a | state_pair_visitors

    state_pair_visitors = state_pair_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    starting_state_visitors = starting_state_visitors.sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    [starting_state_visitors, state_pair_visitors]
  end


end