class FunnelIgnoresController < ApplicationController
  # GET /funnel_ignores
  # GET /funnel_ignores.xml
  def index
    @funnel_ignores = FunnelIgnore.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /funnel_ignores/1
  # GET /funnel_ignores/1.xml
  def show
    @funnel_ignore = FunnelIgnore.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /funnel_ignores/new
  # GET /funnel_ignores/new.xml
  def new
    @funnel_ignore = FunnelIgnore.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /funnel_ignores/1/edit
  def edit
    @funnel_ignore = FunnelIgnore.find(params[:id])
  end

  # POST /funnel_ignores
  # POST /funnel_ignores.xml
  def create
    @funnel_ignore = FunnelIgnore.new(params[:funnel_ignore])

    respond_to do |format|
      if @funnel_ignore.save
        flash[:notice] = 'FunnelIgnore was successfully created.'
        format.html { redirect_to(@funnel_ignore) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /funnel_ignores/1
  # PUT /funnel_ignores/1.xml
  def update
    @funnel_ignore = FunnelIgnore.find(params[:id])

    respond_to do |format|
      if @funnel_ignore.update_attributes(params[:funnel_ignore])
        flash[:notice] = 'FunnelIgnore was successfully updated.'
        format.html { redirect_to(@funnel_ignore) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /funnel_ignores/1
  # DELETE /funnel_ignores/1.xml
  def destroy
    @funnel_ignore = FunnelIgnore.find(params[:id])
    @funnel_ignore.destroy

    respond_to do |format|
      format.html { redirect_to(funnel_ignores_url) }
    end
  end
end
