class DefaultAssigneeSetupController < ApplicationController
  unloadable


  before_filter :find_project

  def index

    @trackers  = @project.trackers
    # @members  = @project.users
    @messages = []
    @default_assignees = DefaultAssigneeSetup.where(:project_id=>@project.id)
    if request.xhr?
      requests = []
      users = @project.assignable_users
      # conditions = ['name like ?', "%#{params[:term]}%"]
      # users = users.where(conditions)
      requests = users.map { |e|  [e[:id],  (e[:firstname] +' '+e[:lastname])] }
      p '====='
      p requests
      p '=====90'
      render :json => {result: requests }
    end
    # destory_trackers_and_members(@trackers,@members)
  end

  def create
  @default_assignee = DefaultAssigneeSetup.find_or_initialize_by_project_id_and_tracker_id(:project_id=> params[:project_id],:tracker_id=>params[:tracker_id])
  @default_assignee.default_assignee_to = params[:assigneed_to_id]
    if @default_assignee.save
       flash[:notice] = l(:notice_successful_update)
       redirect_to settings_project_path(@project, :tab => 'default_assignee')
    else
      @trackers  = @project.trackers
      @members  = @project.users
      render :index
     @messages = []
    end
  end

  def edit
    assignee = DefaultAssigneeSetup.find(params[:id])
    redirect_to settings_project_path(@project, :tab => 'default_assignee', :assigneed_to_id => assignee.default_assignee_to, :tracker_id => assignee.tracker_id)
  end

  def destroy
    assignee = DefaultAssigneeSetup.find(params[:id])
    assignee.destroy
    redirect_to settings_project_path(@project, :tab => 'default_assignee')
  end




  private

  def find_project

    #params[:project_id] = 1
    @project = Project.find(params[:project_id])
  end

end
