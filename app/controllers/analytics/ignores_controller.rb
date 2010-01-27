class Analytics::IgnoresController < ApplicationController

  helper 'analytics/common'

  # GET /ignores
  # GET /ignores.xml
  def index
    @ignores = Analytics::Ignore.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /ignores/1
  # GET /ignores/1.xml
  def show
    @ignore = Analytics::Ignore.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /ignores/new
  # GET /ignores/new.xml
  def new
    @ignore = Analytics::Ignore.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /ignores/1/edit
  def edit
    @ignore = Analytics::Ignore.find(params[:id])
  end

  # POST /ignores
  # POST /ignores.xml
  def create
    @ignore = Analytics::Ignore.new(params[:analytics_ignore])

    respond_to do |format|
      if @ignore.save
        flash[:notice] = 'Analytics::Ignore was successfully created.'
        format.html { redirect_to(@ignore) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /ignores/1
  # PUT /ignores/1.xml
  def update
    @ignore = Analytics::Ignore.find(params[:id])

    respond_to do |format|
      if @ignore.update_attributes(params[:analytics_ignore])
        flash[:notice] = 'Analytics::Ignore was successfully updated.'
        format.html { redirect_to(@ignore) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /ignores/1
  # DELETE /ignores/1.xml
  def destroy
    @ignore = Analytics::Ignore.find(params[:id])
    @ignore.destroy

    respond_to do |format|
      format.html { redirect_to(ignores_url) }
    end
  end
end
