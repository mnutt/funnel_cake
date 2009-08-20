class Analytics::StagesController < Analytics::CommonController


  before_filter :load_state_from_id, :only=>[:show, :stats, :detail, :visitors]
  def load_state_from_id
    @state = params[:id].sub(/-.*/,'')
    @next_state = params[:id].sub(/[^-]*-/,'')
  end

  def index
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def show
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.html # show.html.erb
      format.js do
        render
      end
    end
  end

  def stats
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
    @stats = FunnelCake::Engine.conversion_stats(@state, @next_state, @options)
    respond_to do |format|
      format.js { render }
    end
  end

  def visitors
    @date_range = grab_date_range
    @options = add_filter_options({:date_range=>@date_range, :attrition_period=>1.month})
    respond_to do |format|
      format.html do
        render :partial=>'visitors',
                :locals=>{:state=>@state, :next_state=>@next_state, :options=>@options}
      end
    end
  end




end
