class ApiTicketsController < ApplicationController
  unloadable
  respond_to  :json
  skip_before_filter :verify_authenticity_token,:authorize, :check_external_users
  before_filter :find_project_tracker,:only=>[:create, :create_ticket_with_attachment]
  before_filter :validate_priority_and_date, :only => [:create]
  before_filter :check_detection_params, :only => [:create_update_category, :create_update_tags, :tag_category_statuses]
  before_filter :check_status, :only => :close_ticket
  before_filter :validate_params, :only => :close_ticket
  def index

  end


  def create
    p '------cretae'
    @messages = []
    @issue = Issue.new
    @issue.project_id=@project.id
    @issue.tracker_id=@tracker.id
    @issue.subject = params[:subject]
    @issue.author_id=@author.id
    @issue.description =params[:description]
    @issue.is_system_created = true
    p '=============================userasdad'
    p @created_by
    
    has_ticket = Redmine::Plugin.registered_plugins.keys.include?(:ticketing_approval_system)
    if has_ticket.present?
      #needed_approval = ProjectCategory.find(@category.id).need_approval
    end
  #if !needed_approval || (approval_infos.present? && have_approval) || !approval_infos.present?
    if @issue.save!(:validate => false)
      tag = TicketTag.find_by_name(params[:subject])
      IssueTicketTag.create(:issue_id => @issue.id, :inia_project_id => @for_project.id, :ticket_tag_id => "")
      Issue.set_callback(:create, :after, :send_notification)
      if has_ticket && @issue.tracker.core_fields.include?('approval_workflow')
         project_id = @for_project.id
        # if needed_approval && tag.present? && approval_infos.count >= 1
        #   @issue.ticket_need_approval(approval_infos)
        #   Mailer.deliver_issue_add(@issue)
        # else
          default_assignee =  DefaultAssigneeSetup.find_by_project_id_and_tracker_id(@issue.project_id, @issue.tracker_id)
          default_assignee = default_assignee.present? ? default_assignee : DefaultAssigneeSetup.new
          @issue.assigned_to_id = default_assignee.default_assignee_to
          comments = params[:comment].present? ? params[:comment] : '.'
          journal =  Journal.create(journalized_id: @issue.id, journalized_type: 'Issue', user_id: @author.id,notes: comments )
          old_status = IssueStatus.find_by_name('new')
          status = IssueStatus.find_by_name('open')
          JournalDetail.create(journal_id: journal.id, property: "attr", prop_key: "status_id", old_value: old_status.id, value: status.id)
          @issue.status_id = status.id
          # @priority and @validity obtained by before filter validate_priority_and_date
         p @issue.priority_id = @priority.id if @priority.present?
        p @issue.due_date = @validity if @validity.present?
          @issue.save
          Mailer.deliver_issue_add(@issue)
        # end
      end
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
      render_json_ok(@issue)
    else
      render_validation_errors(@issue)
    end
  Issue.set_callback(:create, :after, :send_notification)
  end

  def create_update_category
    name = params[:oldName].present? ? params[:oldName] : params[:name]
    dep = Project.find_by_identifier(params[:depName])
    pc = ProjectCategory.find_or_initialize_by_project_id_and_cat_name((dep.id rescue nil),name)
    pc.need_approval = true
    pc.internal = false
    # pc.source = source
    pc.cat_name = params[:name]
    begin
      pc.save
      render :json => {:id=>pc.id, :name => pc.cat_name}, :status => 200, :layout => nil
    rescue
      render :json => {:error=>pc.errors}, :status => 200, :layout => nil
    end

  end

  def create_update_tags
    name = params[:oldName].present? ? params[:oldName] : params[:name]
    dep = Project.find_by_identifier(params[:depName])
    cat = ProjectCategory.find_or_initialize_by_project_id_and_cat_name(dep.id,params[:categoryName])
    tag = TicketTag.find_or_initialize_by_project_id_and_name_and_category_id(dep.id , name, cat.id )
    begin
      # tag.source = source
      tag.root=1
      tag.name = params[:name]
      tag.internal = false
      tag.save
      render :json => {:id=>tag.id, :name => tag.name}, :status => 200, :layout => nil
    rescue
      render :json => {:error=>"Something went wrong."}, :status => 200, :layout => nil
    end
  end

  def tag_category_statuses
    helper = Object.new.extend(DashboardHelper)
    a,b,c = helper.get_approval_statuses
    dep = Project.find_by_identifier(params[:depName])
    cat = ProjectCategory.find_or_initialize_by_project_id_and_cat_name(dep.id, params[:categoryName])
    if params[:type]=='category'
     issues =  Issue.find_by_sql("select * from issues i join issue_ticket_tags itt on i.id=itt.issue_id
join ticket_tags tt on itt.ticket_tag_id=tt.id join project_categories pc on pc.id=tt.category_id
where i.status_id in (#{a.present? ? a : ''},#{b.present? ? b : '' },#{c.present? ? c : ''}) and pc.id=#{cat.id} ")
     render :json => {:status=>issues.count == 0}, :status => 200, :layout => nil
    elsif params[:type]=='tag'
      tag = TicketTag.find_or_initialize_by_project_id_and_name_and_category_id((dep.id rescue nil),params[:name],  (cat.id rescue nil))
      if tag.id.present?
        issues =  Issue.find_by_sql("select * from issues i join issue_ticket_tags itt on i.id=itt.issue_id join ticket_tags tt on itt.ticket_tag_id=#{tag.id} where i.status_id in (#{a.present? ? a : ''},#{b.present? ? b : '' },#{c.present? ? c : ''}) and tt.id=#{tag.id} ")
        render :json => {:status=>issues.count == 0}, :status => 200, :layout => nil
      else
        render :json => {:status=>"Tag not found"}, :status => 200, :layout => nil
      end
    else
      render :json => {:status=>"Type not found"}, :status => 200, :layout => nil
    end
  end

  def create_ticket_with_attachment
    @issue = Issue.new
    @issue.project_id=@project.id
    @issue.tracker_id=@tracker.id
    @issue.subject = params[:subject]
    @issue.author_id=@author.id
    @issue.description =params[:description]
    @issue.is_system_created = true
    if @issue.save!(:validate => false)
      IssueTicketTag.create(:issue_id => @issue.id, :inia_project_id => @for_project.id, :ticket_tag_id => "")
     # Issue.set_callback(:create, :after, :send_notification)
      #----------------------------------------------
      file = File.join(Rails.root, 'app', 'DC28.csv')
      raw = File.read(file)
      file_name =  File.basename(file)
      @attachment = Attachment.new(:file => raw)
      @attachment.author = @author
      @attachment.filename = 'DC.csv'.presence || Redmine::Utils.random_hex(16)
      @attachment.save
      attachment = {"1"=>{"filename"=>file_name, "description"=>"", "token"=>@attachment.token}}
      @issue.save_attachments(attachment)
      #----------------------------------------------
      default_assignee =  DefaultAssigneeSetup.find_by_project_id_and_tracker_id(@project.id, @tracker.id)
      default_assignee = default_assignee.present? ? default_assignee : DefaultAssigneeSetup.new
      @issue.assigned_to_id = default_assignee.default_assignee_to
      #journal =  Journal.create(journalized_id: @issue.id, journalized_type: 'Issue', user_id: User.current.id,notes: comments )
      old_status = IssueStatus.find_by_name('new')
      status = IssueStatus.find_by_name('open')
      #JournalDetail.create(journal_id: journal.id, property: "attr", prop_key: "status_id", old_value: old_status.id, value: status.id)
      @issue.status_id = status.id
      @issue.save
      #Mailer.deliver_issue_add(@issue)
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
      render_json_ok(@issue)
    else
      render_validation_errors(@issue)
    end
    #Issue.set_callback(:create, :after, :send_notification)
  end

  def close_ticket
    # @status value obtained by before filter check status method
    errors = []
    p params[:id]
    if (params[:ticketId].present? || params[:id].present?) 
      id = params[:ticketId].present? ? params[:ticketId] : params[:id]
      ticket = Issue.find(id)
      project = Project.find_by_dept_code(params[:deptCode]) 
      if project.present?
        if project.id == ticket.project_id
          comments = params[:comments].present? ? params[:comments] : ''
          requested_user = UserOfficialInfo.find_by_employee_id(params[:requesterId])
          if requested_user.present?
            user = User.find(requested_user.user_id)
            ticket.init_journal(user ,comments)
            ticket.status_id = @status.id if @status.present?
            if ticket.save(validate: false)
              render_json_ok(ticket)
            else
              render_json_errors(ticket.errors)
            end
          else
            errors <<  "Employee not found" 
          end
        else 
          errors << "Deptcode doesn't match for requested Issue" 
        end
      else
        errors << "Invalid Deptcode" 
      end
    else 
      errors << "Ticket Id required..!" 
    end
    if errors.present?
      render_json_errors(errors)
    end
  end
 
 
  private

  def check_detection_params
    errors = []
    unless params[:name].present?
      errors << "Name Not found"
    end
    if params[:depName].present?
      project = Project.find_by_identifier(params[:depName])
      unless project.present?
        errors << "Department Name Not found in the list"
      end
    else
      errors << "Department Name Not found"
    end
    if errors.present?
      render_json_errors(errors)
    end
  end

  def verify_message_api_key
    if request.present? && request.headers["key"].present?
        find_valid_key = Redmine::Configuration['hrms_api_key'] || File.join(Rails.root, "files")
       (find_valid_key == request.headers["key"].to_s) ? true : render_json_errors("Key Invalid.")
    else
      render_json_errors("Key not found in Url.")
    end
  end

  def find_project_tracker
    errors=[]
    p params
    if params[:deptCode].present?
      @project = Project.find_by_dept_code(params[:deptCode])
    elsif params[:deptName].present?
      @project = Project.find_by_identifier(params[:deptName])
      p '---------------'
      p @project
      if !@project.present?
        errors << "Invalid Identifier..!"
      end
    else
      errors <<  "Dept code or Name is required."
    end
    if @project.present?
      @tracker = Tracker.find_by_name(@project.name)
    end
    if !params[:employeeId].blank?
      author = UserOfficialInfo.find_by_employee_id(params[:employeeId])
    if author.present?
      @author = author.user
    else
      errors << "Employee Id Not found"
    end
    else
      errors << "Employee Id required..!"
    end

    if !params[:project].blank?
      @for_project=IniaProject.find_by_identifier(params[:project])
      unless @for_project
        @for_project=IniaProject.find_by_name(params[:project])
        unless @for_project
          errors << "Project Not Found..!"
        end
      end

    else
      errors << "Project required..!"
    end
    if !params[:category].blank?
      p '=================gnre---------'
      @category =ProjectCategory.find_by_cat_name_and_project_id(params[:category],@project.id) rescue nil
      unless @category
        errors << "Category Not Found..!"
      end
    else
      errors << "Category required..!"
    end
    if @author.present? && @for_project.present?
      member = IniaMember.find_by_user_id_and_project_id(@author.id,@for_project.id)
        unless member
          @for_project=IniaProject.find_by_name(params[:project])
          if @for_project.present?
            member = IniaMember.find_by_user_id_and_project_id(@author.id,@for_project.id)
            unless member
              errors << "Requested person is not a member of project..!"
            end
          else
            errors << "Requested person is not a member of project..!"
          end
        end
    end
    if errors.present?
      render_json_errors(errors)
    end
   
  end

  def check_status
    if params[:status].present?
      if params[:status] == "Resolved" || params[:status] == "Closed"
        @status = IssueStatus.find_by_name(params[:status])
      else
        render :json => "Invalid status..!"
      end
    else
      render :json => "Status required..!"
    end
  end

  def validate_params
    errors = []
    unless params[:requesterId].present?
      errors <<  "requesterId required..!"
    end

    unless params[:deptCode].present?
      errors << 'Deptcode required..!'
    end
    if errors.present?
      render_json_errors(errors)
    end
  end

  def validate_priority_and_date
    if params[:priority].present?
      p @priority = IssuePriority.find_by_name(params[:priority])
      unless @priority.present?
         render :json => "priority not found..!"
      end
    end

    if params[:validTill].present?
      begin
      @validity = params[:validTill].to_date
      if @validity.present?
        unless @validity > Date.today
          render :json => "validTill date should be greater than today"
        end
      end
      rescue
        render :json => "validTill is not a date..!"
      end
    end
  end

  def render_json_errors(errors)
    render :text => errors, :status => 500,:errors=>errors, :layout => nil
  end

  def render_json_ok(issue)
    p '===================== yes ------------'
    render_json_head(issue,"ok")
  end


  def render_json_head(issue,status)
    p '===================== yes --------ko----'
    render :json => {:ticket_id=>issue.id, :status_name => issue.status.name, :updated_on => issue.updated_on}, :status => 200, :layout => nil
  end


end
