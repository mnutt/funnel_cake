class Analytics::DashboardsController < Analytics::CommonController

  def diagram
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.js { render }
    end
  end

  def overview
  end

end