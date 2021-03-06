class Mailer < ActionMailer::Base
  # layout 'mailer'

  def self.default_url_options
    { :host => "nanba.objectfrontier.com/", :protocol => 'https' }
  end


  def request_remainder_mail(issue)
    redmine_headers 'Project' => issue.project.identifier
    @author = issue.author
    @subject = issue.subject
    @description = issue.description
    @date = issue.due_date.strftime("%d-%b-%Y")
    @dept_name = issue.project.name
    cc_id = ApprovalRole.set_assignee_value(issue)
    begin
      p '======cc======='
      p cc_id
      p cc_users = User.where(:id => cc_id, :type => 'User').last.mail
    rescue
      p '======cc======1='
      p cc_users =User.find_by_sql("SELECT mail FROM users INNER JOIN groups_users ON users.id = groups_users.user_id WHERE users.type IN ('User', 'AnonymousUser') AND groups_users.group_id =#{cc_id}").map(&:mail)
    end
    @comment = "Your request validity will be expire on #{issue.due_date}, If you want to renewal please create a ticket in NANBA."
    @news_url = url_for(:controller => 'issues', :action => 'show', :id => issue.id)
    mail(:to => @author.mail,:cc => cc_users, :subject => "Notification from #{issue.project.name} ")
  end

  def admin_remainder(issue)
    redmine_headers 'Project' => issue.project.identifier
    @author = issue.author
    @news_url = url_for(:controller => 'issues', :action => 'show', :id => issue.id)
    @subject = issue.subject
    @description = issue.description
    @date = issue.due_date.strftime("%d-%b-%Y")
    cc_id = ApprovalRole.set_assignee_value(issue)
    begin
      cc_users = User.where(:id => cc_id, :type => 'User').last.mail
    rescue
      cc_users =User.find_by_sql("SELECT mail FROM users INNER JOIN groups_users ON users.id = groups_users.user_id WHERE users.type IN ('User', 'AnonymousUser') AND groups_users.group_id =#{cc_id}").map(&:mail)
    end
    mail :to => cc_users ,:cc => @author.mail,:subject => "ALERT ! - REVOKE ACCESS FOR EXPIRED PRIVILEGES.",:importance => "High",'X-Priority' => '1'
  end

  def job_notification(dept, status)
    project = Project.find(dept)
    redmine_headers 'Project' => project.identifier
    @subject = status
#    cc_id = DefaultAssigneeSetup.find_by_project_id(dept).default_assignee_to

    begin 
      cc_users = AdminDetail.first.email
      mail :to => cc_users ,:subject => 'Ticket request job was '+status

      #cc_users = User.where(:id => cc_id, :type => 'User').last.mail
    rescue
      logger.warn "email delivery error = #{e}"
 #     cc_users =User.find_by_sql("SELECT mail FROM users INNER JOIN groups_users ON users.id = groups_users.user_id WHERE users.type IN ('User', 'AnonymousUser') AND groups_users.group_id =#{cc_id}").map(&:mail)
    end
  end

  def mail(headers={}, &block)
    headers.reverse_merge! 'X-Mailer' => 'Redmine',
                           'X-Redmine-Host' => 'nanba.objectfrontier.com/',
                           'X-Redmine-Site' => 'NANBA',
                           'X-Auto-Response-Suppress' => 'OOF',
                           'Auto-Submitted' => 'auto-generated',
                           'From' =>  "nanba@object-frontier.com" ,
                           'List-Id' => "<#{'nanba@object-frontier.com'.gsub('@', '.')}>"

    if @author #&& @author.pref.no_self_notified
      headers[:to].delete(@author.mail) if headers[:to].is_a?(Array)
      headers[:cc].delete(@author.mail) if headers[:cc].is_a?(Array)
    end

    if @message_id_object
      headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
    end
    if @references_objects
      headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
    end

    m = if block_given?
          super headers, &block
        else
          super headers do |format|
            format.text
            format.html unless false
          end
        end
    m
  end


  private
  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v.to_s }
  end

end
