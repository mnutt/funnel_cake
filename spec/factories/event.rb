Factory.define :event, :class=>Analytics::Event do |model|
  model.from 'unknown'
  model.to 'unknown'
  model.created_at DateTime.civil(1978, 5, 12, 12, 0, 0, Rational(-5, 24)).advance(:hours=>-2)
  model.visitor_id 1
  model.url 'http://test.com'
  model.name 'Event Name'
  model.referer 'http://iwasherebefore.now'
  model.user_agent 'not IE6'
end
