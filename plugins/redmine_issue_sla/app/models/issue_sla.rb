class IssueSla < ActiveRecord::Base
  belongs_to :project, :class_name => 'Project', :foreign_key => 'project_id'
  belongs_to :priority, :class_name => 'IssuePriority', :foreign_key => 'priority_id'
  belongs_to :tracker, :class_name => 'Tracker', :foreign_key => 'tracker_id'
  validates_presence_of :priority, :project
  validates_numericality_of :allowed_delay, :allow_nil => true
  has_many :issues,:class_name => 'Issue', :foreign_key => 'priority_sla_id'
  attr_protected :priority_id, :project_id
  
  # before_save :update_issues


  # add severioty to project
  def self.create_slas(project, params)
     priority_ids = params[:priority_ids]
    tracker_id = params[:tracker_id]
    if priority_ids.present?
    priority_ids.each do |priority_id|
      if params[:issue_sla][priority_id.to_sym].present?
        issue_priority_id = IssueSla.where(:project_id=>project.id,:tracker_id=>tracker_id,:priority_id=>priority_id)
        if issue_priority_id.present?
          issue_priority_id.last.update_attributes(:allowed_delay => params[:issue_sla][priority_id.to_sym])
        else
          issue_sla = IssueSla.new
          issue_sla.project_id = project.id
          issue_sla.tracker_id = tracker_id
          issue_sla.priority_id = priority_id.to_i
          issue_sla.allowed_delay = params[:issue_sla][priority_id.to_sym]
          issue_sla.save
        end
        resolve = IssueStatus.find_by_name('Resolved')
        p '------------------------------------'
# p [resolve.id, priority_id]
#         issues =  project.issues.open.where("status_id != #{resolve.id} and priority_id=#{priority_id}")
#         sla_rec = IssueSla.where(:tracker_id => issues.last.tracker.id, :project_id => project.id, :priority_id => priority_id.to_i)
#         issues.update_all(:estimated_hours =>sla_rec.last.allowed_delay )
        p '------------------------------------'
        project.issues.open.where("status_id != #{resolve.id} and priority_id=#{priority_id}").each do |issue|
          sla_rec = IssueSla.where(:tracker_id => issue.tracker.id, :project_id => issue.project.id, :priority_id => priority_id.to_i)
          next if issue.estimated_hours == sla_rec.last.allowed_delay
          Issue.skip_callbacks = true
          issue.update_attributes(:estimated_hours => sla_rec.last.allowed_delay)
          Issue.skip_callbacks = false
        end
      else
        find_sla_with_priority = IssueSla.where(:project_id=>project.id,:tracker_id=>tracker_id,:priority_id=>priority_id).first_or_create
        find_sla_with_priority.update_attributes(:allowed_delay=>"0.0")
      end
    end
    not_found_slas =  IssueSla.where(:project_id=>project.id,:tracker_id=>tracker_id).where("priority_id  NOT IN (?)",priority_ids)
    if not_found_slas.present?
    not_found_slas.each do |not_found|
      not_found.delete
    end
    end
    else
     IssueSla.delete_all(:project_id=>project.id,:tracker_id=>tracker_id)
    end

  end

  def self.create_or_update_response_time(project,params)
    tracker_id = params[:tracker_id]
    response_time = "#{params[:response_hours]}.#{params[:response_min]}"
    ticket_closing = params[:ticket_closing]
    response_sla =ResponseSla.where(:project_id=>project.id,:tracker_id => tracker_id).first_or_create
    response_sla.update_attributes(:response_set_time => response_time, :ticket_closing => ticket_closing)
  end


  private
  def update_issues

    resolve = IssueStatus.find_by_name('Resolved')
    project.issues.open.where("priority_id = #{priority.id} and status_id != #{resolve.id} and estimated_hours != #{allowed_delay}").all.each do |issue|
      next if issue.first_response_date.present?
p '==================diff=============='
      p issue.estimated_hours == allowed_delay

      date = nil
      if allowed_delay.present?
        date = allowed_delay.hours.since(issue.created_on).round
      end
      if issue.expiration_date != date
        issue.init_journal(User.current)
        issue.attributes_before_change['expiration_date'] = date
        Issue.skip_callbacks = true
        issue.expiration_date = date
        issue.issue_sla = allowed_delay
        issue.save
        Issue.skip_callbacks = false
      end
    end
  end
end
