class Analytics::VisitorsController < Analytics::CommonController
  unloadable if RAILS_ENV=='development'

  # GET /visitors
  # GET /visitors.xml
  def index

    # Analytics::Visitor.recent.with_user.including_events.ordered
    @visitors_with_users = Analytics::Visitor.find(:all, :conditions=>{
      :created_at.gt=>1.month.ago.utc,
      :user_id.ne=>nil,
    }, :order=>'created_at DESC')

    # @visitors_without_users = Analytics::Visitor.recent.without_user.ordered
    @visitors_without_users = Analytics::Visitor.find(:all, :conditions=>{
      :created_at.gt=>1.month.ago.utc,
      :user_id=>nil,
    }, :order=>'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /visitors/1
  # GET /visitors/1.xml
  def show
    @visitor = Analytics::Visitor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /visitors/new
  # GET /visitors/new.xml
  def new
    @visitor = Analytics::Visitor.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /visitors/1/edit
  def edit
    @visitor = Analytics::Visitor.find(params[:id])
  end

  # POST /visitors
  # POST /visitors.xml
  def create
    @visitor = Analytics::Visitor.new(params[:visitor])

    respond_to do |format|
      if @visitor.save
        flash[:notice] = 'Analytics::Visitor was successfully created.'
        format.html { redirect_to(@visitor) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /visitors/1
  # PUT /visitors/1.xml
  def update
    @visitor = Analytics::Visitor.find(params[:id])

    respond_to do |format|
      if @visitor.update_attributes(params[:visitor])
        flash[:notice] = 'Analytics::Visitor was successfully updated.'
        format.html { redirect_to(@visitor) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /visitors/1
  # DELETE /visitors/1.xml
  def destroy
    @visitor = Analytics::Visitor.find(params[:id])
    @visitor.destroy

    respond_to do |format|
      format.html { redirect_to(visitors_url) }
    end
  end
end
