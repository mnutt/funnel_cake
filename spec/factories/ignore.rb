Factory.define :ignore, :class=>Analytics::Ignore do |model|
  model.ip '123.123.123.123'
  model.name 'Ignore Name'
end
