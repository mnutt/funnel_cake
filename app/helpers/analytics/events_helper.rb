module Analytics::EventsHelper

  # Grab raw position data from the diagram xdot
  XDOT_FILE = File.join(RAILS_ROOT, 'app', 'views', 'analytics', 'events', '_diagram.xdot.erb')
  RAW_STATE_POSITIONS_ARR = File.open(XDOT_FILE).read.split(/\n/).
                          collect { |l| l.match(/(\w+) \[label=\".*pos=\"(\d+,\d+)\"/) }.
                          delete_if {|m| m.nil?}.
                          collect {|m| [m[1].to_sym, {:left=>m[2].split(/,/)[0].to_i, :top=>m[2].split(/,/)[1].to_i}] }
  RAW_STATE_POSITIONS = Hash[*RAW_STATE_POSITIONS_ARR.flatten]
  state_pos_bounds_matches = File.open(XDOT_FILE).read.match(/bb=\"0,0,(\d+),(\d+)\"/ms)
  STATE_POSITION_BOUNDS = {:width=>state_pos_bounds_matches[1].to_i, :height=>state_pos_bounds_matches[2].to_i}
  STATE_POSITIONS = RAW_STATE_POSITIONS.each_value{ |h| h[:top] = STATE_POSITION_BOUNDS[:height] - h[:top]; h }
  POS_PADDING = 8
  POS_SCALE = 0.6 * 96/72

  def state_position(state)
    Analytics::Visitor.primary_states.index(state.to_sym) * 120
    # pos = STATE_POSITIONS[state.to_sym]
    # return 0 if pos.nil?
    # pos[:top]*POS_SCALE - POS_PADDING
  end

end
