class Analytics::Event

  include Comparable
  def <=>(other)
    return 0 if created_at.nil? or other.created_at.nil?
    created_at <=> other.created_at
  end

end
