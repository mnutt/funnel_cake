module Analytics::StagesHelper

  def state_graph_visitors(state, opts)
    next_state = next_state_from(state)

    visitors = FunnelCake::Engine.conversion_visitors(state, next_state, opts)

    starting_visitors = visitors[:start].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    ending_visitors = visitors[:end].sort {|a,b| (a.user ? a.user.name : '') <=> (a.user ? a.user.name : '') }
    [starting_visitors, ending_visitors]
  end

end