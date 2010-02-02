Factory.define :visitor, :class=>Analytics::Visitor do |model|
  model.key '1010'
  model.state 'unknown'
  model.ip '555.555.555.555'
  model.user_id 1
end
