Factory.define :visitor, :class=>Analytics::Visitor do |model|
  model.sequence(:key) {|n| "key#{n}" }
  model.sequence(:ip) {|n| "#{(n % 9).to_s*3}.#{(n % 9).to_s*3}.#{(n % 9).to_s*3}.#{(n % 9).to_s*3}" }
  model.state 'unknown'
  model.user_id 1
end
