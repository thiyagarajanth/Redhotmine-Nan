class ApproverSla < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :tracker
  belongs_to :approver_role

  def self.create_or_update(project, params)
    sla = params['approver_sla']
    sla.each do |key, value|
      priority = IssuePriority.find_by_name(key)
      value.each do |key, value|
        apsla = ApproverSla.find_or_initialize_by_project_id_and_tracker_id_and_approval_role_id_and_priority_id(project.id, params[:tracker_id],key, priority.id)
        apsla.estimated_time = value
        apsla.save
      end
    end if sla
  end
end