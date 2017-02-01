module SlaReportsHelper

  def retrieve_date_range(period, from, to, type)
    helper = Object.new.extend(WktimeHelper)
    @free_period = false
    @from, @to = nil, nil
    if type == '1' || (type.nil? && !period.nil?)

      case period.to_s
        when 'today'
          @from = @to = Date.today
        when 'yesterday'
          @from = @to = Date.today - 1
        when 'current_week'
          @from = helper.getStartDay(Date.today - (Date.today.cwday )%7)
          @to = @from + 6
        when 'last_week'
          @from = helper.getStartDay(Date.today - 7 - (Date.today.cwday )%7)
          @to = @from + 6
        when '7_days'
          @from = Date.today - 7
          @to = Date.today
        when 'current_month'
          @from = Date.civil(Date.today.year, Date.today.month, 1)
          @to = (@from >> 1)
        when 'last_month'
          @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
          @to = (Date.civil(Date.today.year, Date.today.month, -1)) << 1
        when '30_days'
          @from = Date.today - 30
          @to = Date.today
        when 'current_year'
          @from = Date.civil(Date.today.year, 1, 1)
          @to = Date.civil(Date.today.year, 12, 31)
        when 'all'
          @from = Date.civil(2000, 1, 1)
          @to = Date.civil(Date.today.year, 12, 31)
      end
      @from, @to = @to.to_s+" 23:59:59", @from.to_s+" 00:00:00"
    elsif type == '2' || (type.nil? && (!from.nil? || !to.nil?))
      begin; @from = from.to_s.to_date unless from.blank?; rescue; end
      begin; @to = to.to_s.to_date unless to.blank?; rescue; end
      @free_period = true
      @fr = @from
      @t = @to
      @from, @to = @to.to_s+" 23:59:59", @from.to_s+" 00:00:00"
    else
      @from = Date.civil(Date.today.year, Date.today.month, 1)
      @to = (@from >> 1) - 1
      @from, @to = @to.to_s+" 23:59:59", @from.to_s+" 00:00:00"
    end
    @from, @to = @to.to_s+" 23:59:59", @from.to_s+" 00:00:00" if @from && @to && @from > @to
  end



  def get_filter_results(params)
    p '======re====='
     project = Project.find_by_identifier(params[:project_id])
    dgo_sla = project.enabled_modules.map(&:name).include?('actual_sla')
    p '=========status_cond'
    if dgo_sla == true
      p status_cond = "where name = 'closed'"
    else
      p status_cond = "where name in ('closed','resolved')"
    end
    user = (params['user_id']=='0' || params['user_id']==nil) ? '' : "and user_id =#{params['user_id']}"
    resloved_issues = "select journalized_id from journals where id in (select journal_id from journal_details where value in (select id from issue_statuses #{status_cond} and prop_key='status_id')) #{user} "
    retrieve_date_range(params[:period],params[:from],params[:to],params[:period_type])
    i_ids = "where id in (#{resloved_issues} and created_on >= '#{@from}' and created_on <= '#{@to}' )"
    @project = Project.find_by_identifier(params[:project_id]) #if @project.nil?
    if params[:page_type].present? && params[:page_type] == '1'
      hm = @project.response_sla.response_set_time.to_s.split('.')
      mm = hm[1]+'0'
      hh = hm[0].to_i * 60
      response_sla = hh + mm.to_i
      response = "select aj.journalized_id from (select j.journalized_id,iss.name,jd.prop_key, j.created_on from journals j, journal_details jd, issue_statuses iss where j.id = jd.journal_id and jd.value = iss.id and iss.name = 'open' and jd.prop_key='status_id' group by j.journalized_id) oj, issue_statuses ss,journal_details dd,journals ji,(select j.journalized_id,iss.name,jd.prop_key, j.created_on from journals j, journal_details jd, issue_statuses iss where j.id = jd.journal_id and jd.value = iss.id and iss.name = 'assigned' and jd.prop_key='status_id') aj where oj.journalized_id = aj.journalized_id "
    end
    @status_issues= []
    @active_status_issues = []
    @active_status_id = []
    @removed_status = ["Resolved","Rejected","Closed"]
    @sla_issues = []
    @sla_avg = []
    x,y,z = 0,0,0
    p '======isi====='
    @issues = Issue.find_by_sql("select * from issues #{i_ids}  ")
    @priority_issues = []
    @project.issue_slas.where("allowed_delay > 0").each do |sla|

      if params['period_type']=='1' || params['period_type']=='2'
        cond = "and priority_sla_id=#{sla.id}"
      else
        cond = "where priority_sla_id=#{sla.id}"
      end
      total_priority_issues = Issue.find_by_sql("select count(*) as count from issues where updated_on >= '#{@from}' and updated_on <= '#{@to}' "+cond).map(&:count).last
      status_issues = {}
      active_status_issues = []
      IssueStatus.order('position').all.each do |status|
        total_issues  = Issue.find_by_sql("select * from issues where status_id=#{status.id} and updated_on BETWEEN '#{@from}' AND '#{@to}'  "+cond).count
        status_issues[:"#{status.name}"] = total_issues #if total_issues > 0
        unless @removed_status.include?(status.name)
          @active_status_id << status.id
          active_status_issues << total_issues
          #p active_count << total_issues
        end
      end
      @priority_issues << total_priority_issues
      @status_issues << { sla.priority.name => status_issues}
      p @active_status_issues << active_status_issues.sum
p '=================type======page========'
      p params[:page_type]
      if params[:page_type].present? && params[:page_type] == '2'
        dgo = "select issue_id, sum(pre_status_duration)/100 as total_hr from sla_times "
        dep = "select issue_id, sum(hours) as total_hr FROM `time_entries` "
        dept_sla = dgo_sla ? dgo : dep
        t_issues = "#{dept_sla} where issue_id in (select id from issues #{i_ids}  #{cond}) GROUP BY issue_id"
       
        ids  = Issue.find_by_sql(t_issues)
        met_cond = "#{t_issues} HAVING total_hr <=  #{sla.allowed_delay} "
        not_met_cond = "#{t_issues} HAVING total_hr >  #{sla.allowed_delay} "
        met = TimeEntry.find_by_sql(met_cond).map(&:issue_id)
        not_met = TimeEntry.find_by_sql(not_met_cond).map(&:issue_id)
        percent = (met.count.to_f/ids.count.to_f) * 100
      elsif params[:page_type].present? && params[:page_type] == '1'
        p '===============1111111'
        ids  = Issue.find_by_sql("select id from issues #{i_ids} "+cond)
        res_not_met_con = " and aj.journalized_id in (select id from issues  #{i_ids}  and updated_on >= '#{@from}' and updated_on <= '#{@to}' #{cond}) and TIMESTAMPDIFF(MINUTE,oj.created_on, aj.created_on) > #{response_sla} and ji.id = dd.journal_id and dd.value = ss.id and ss.name = 'resolved'  and dd.prop_key='status_id' and oj.journalized_id = ji.journalized_id group by aj.journalized_id"
        p res_met_con = " and aj.journalized_id in (select id from issues #{i_ids} and updated_on >= '#{@from}' and updated_on <= '#{@to}' #{cond}) and TIMESTAMPDIFF(MINUTE,oj.created_on, aj.created_on) <= #{response_sla} and ji.id = dd.journal_id and dd.value = ss.id and ss.name = 'resolved' and dd.prop_key='status_id' and oj.journalized_id = ji.journalized_id group by aj.journalized_id"
        met = Journal.find_by_sql(response + res_met_con ).map(&:journalized_id)
        not_met = Journal.find_by_sql(response + res_not_met_con).map(&:journalized_id)
        percent = (met.count.to_f/ids.count.to_f) * 100
      end
      x = x + ids.count
      y = y + met.count
      z = z + not_met.count
      p '======hereend---'
     p  @sla_issues << { sla.priority.name => ids.count,:met_sla => met, :not_met => not_met, :percent => (percent.present? && percent.nan?) ? 0 : percent  }
      # raise
    end
    p per = ((y.to_f/x.to_f)*100).to_f.nan? ? 0.0 : ((y.to_f/x.to_f)*100).round(2)
    @sla_avg << [x,y,z, per]
    p "===============nan"
    # p @sla_avg.flatten.reject! &:nan?
    @sla_avg.flatten
  end

  def get_user_rating_issues(params, project)
    retrieve_date_range(params['period'], params['from'], params['to'], params['period_type'])
    UserRating.find_by_sql("select issue_id from user_ratings where project_id=#{project.id} and rated_for=#{params[:rated_for]} and created_at >= '#{@from}' and created_at <= '#{@to}' ").map(&:issue_id)
  end

  def get_issues_list(params)
    p '---------------------get_issues_list'
    project = Project.find_by_identifier(params[:project_id])
    dgo_sla = project.enabled_modules.map(&:name).include?('actual_sla')
    p '=========status_cond'
    if dgo_sla == true
      p status_cond = "where name = 'closed'"
    else
      p status_cond = "where name in ('closed','resolved')"
    end
    user = (!params['user_id'].present? || params['user_id']=='0') ? '' : "and user_id =#{params['user_id']}"
    resloved_issues = "select journalized_id from journals where id in (select journal_id from journal_details where value in (select id from issue_statuses #{status_cond} and prop_key='status_id')) #{user} order by id desc"
    project = Project.find_by_identifier(params[:project_id])
    dgo_sla = project.enabled_modules.map(&:name).include?('actual_sla')
    retrieve_date_range(params['period'], params['from'], params['to'], params['period_type'])
    i_ids = "where id in (#{resloved_issues})  "
    period = "and updated_on >= '#{@from}' and updated_on <= '#{@to}'"
    @project = Project.find_by_identifier(params[:project_id]) if @project.nil?
    if params[:page_type].present? && params[:page_type] == '1'
      hm = @project.response_sla.response_set_time.to_s.split('.')
       mm = hm[1]+'0'
       hh = hm[0].to_i * 60
       response_sla = hh + mm.to_i
      response = "select aj.journalized_id from (select j.journalized_id,iss.name,jd.prop_key, j.created_on from journals j, journal_details jd, issue_statuses iss where j.id = jd.journal_id and jd.value = iss.id and iss.name = 'open' and jd.prop_key='status_id') oj, issue_statuses ss,journal_details dd,journals ji,(select j.journalized_id,iss.name,jd.prop_key, j.created_on from journals j, journal_details jd, issue_statuses iss where j.id = jd.journal_id and jd.value = iss.id and iss.name = 'assigned' and jd.prop_key='status_id') aj where oj.journalized_id = aj.journalized_id "
    end
    @sla_issues = []
    @issues = Issue.find_by_sql("select * from issues #{i_ids} #{period} ")
    
    @project.issue_slas.where("allowed_delay > 0").each do |sla|
        if params['period_type']=='1' || params['period_type']=='2'
          cond = "and priority_sla_id=#{sla.id}" 
        else
          cond = "where priority_sla_id=#{sla.id}" 
        end
      if params[:page_type].present? && params[:page_type] == '2'
        p '================ type 2 ========i========'
        dgo = "select issue_id, sum(pre_status_duration)/100 as total_hr from sla_times "
        dep = "select issue_id, sum(hours) as total_hr FROM `time_entries` "
        dept_sla = dgo_sla ? dgo : dep
        t_issues = "#{dept_sla} where issue_id in (select id from issues #{i_ids} #{period}  #{cond}) GROUP BY issue_id"
        ids  = Issue.find_by_sql(t_issues).map(&:issue_id)
        met_cond = "#{t_issues} HAVING total_hr <=  #{sla.allowed_delay} "
        not_met_cond = "#{t_issues} HAVING total_hr >  #{sla.allowed_delay} "
      
         TimeEntry.find_by_sql(not_met_cond)
         met = TimeEntry.find_by_sql(met_cond).map(&:issue_id)
         not_met = TimeEntry.find_by_sql(not_met_cond).map(&:issue_id)
         percent = (met.count.to_f/ids.count.to_f) * 100
      elsif params[:page_type].present? && params[:page_type] == '1'
       p '================ type 1 ================'
        ids  = Issue.find_by_sql("select id from issues #{i_ids} #{period}"+cond).map(&:id)
        res_not_met_con = " and aj.journalized_id in (select id from issues  where id > 0  #{period} #{cond}) and TIMESTAMPDIFF(MINUTE,oj.created_on, aj.created_on) > #{response_sla} and ji.id = dd.journal_id and dd.value = ss.id and ss.name = 'resolved'  and dd.prop_key='status_id' and oj.journalized_id = ji.journalized_id"
        res_met_con = " and aj.journalized_id in (select id from issues where id > 0 #{period} #{cond}) and TIMESTAMPDIFF(MINUTE,oj.created_on, aj.created_on) < #{response_sla} and ji.id = dd.journal_id and dd.value = ss.id and ss.name = 'resolved' and dd.prop_key='status_id' and oj.journalized_id = ji.journalized_id"
        p '==== close==='
        met = Journal.find_by_sql(response + res_met_con ).map(&:journalized_id)
        not_met = Journal.find_by_sql(response + res_not_met_con).map(&:journalized_id)
        percent = (met.count.to_f/ids.count.to_f) * 100
      end
      
      @sla_issues << { sla.priority.name => ids,:met_sla => met, :not_met => not_met, :percent => percent.nan? ? 0 : percent  }
    end
    @sla_issues[params[:pos].to_i].each_with_index do |x, i|
     return	x[1] if i==params[:status].to_i
    end

  end

  def get_validity_list(project)
   TicketTag.where("project_id=#{project.id} and validity > 0")
  end

  def team_members(project)
    TeamProfile.where(:project_id => project.id).order('name')
  end

  def update_query_param(priority_id, status_id, project_id)
    if params['period_type'] == '1'
      case params['period']
      when 'today'
        @datevalue = "t"
      when 'yesterday'
        @datevalue = "ld" 
      when 'current_week'
        @datevalue = "w"
      when 'last_week'
        @datevalue = "lw"
      when 'current_month'
        @datevalue = "m"  
      when 'last_month'
          @datevalue = "lm"
      when 'current_year'
        @datevalue = "y"
      when 'last_2_weeks'
        @datevalue = "l2w"
      when 'last_7_days'
        @datevalue = "lw"
      when '30_days'
        @datevalue = "m"
      when 'all'
        @datevalue =  "*" 
      else
      end
      
      project = Project.find(project_id)
      if project.enabled_modules.map(&:name).include?('actual_sla')

      {"set_filter"=>"1", "f"=>["status_id", "priority_id", "updated_on", ""],
                                "op"=>{"status_id"=>"=", "priority_id"=>"=","updated_on"=>@datevalue}, 
                                "v"=>{"status_id"=>status_id, "priority_id"=>priority_id }, 
                                "c"=>["subject", "author", "assigned_to", "priority", "status","pending_time"], 
                                "group_by"=>"", "project_id"=>project_id}
      else
        {"set_filter"=>"1", "f"=>["status_id", "priority_id", "updated_on", ""],
                                "op"=>{"status_id"=>"=", "priority_id"=>"=","updated_on"=>@datevalue}, 
                                "v"=>{"status_id"=>status_id, "priority_id"=>priority_id }, 
                                "c"=>["subject", "author", "assigned_to", "priority", "status","updated_on"], 
                                "group_by"=>"", "project_id"=>project_id}
      end
    else
      @from = params['from'].present? ? Time.parse(params['from']).strftime("%Y-%m-%d") : ''
      @to = params['to'].present? ? Time.parse(params['to']).strftime("%Y-%m-%d") : ''
      too = @to.present? ? (Time.parse(params['to'])+1.day).strftime("%Y-%m-%d") : ''
      {"set_filter"=>"1", "f"=>["status_id", "priority_id", "updated_on", ""],
                                "op"=>{"status_id"=>"=", "priority_id"=>"=","updated_on"=>"><"}, 
                                "v"=>{"status_id"=>status_id, "priority_id"=>priority_id, "updated_on" => ["#{@from}","#{@to}"]}, 
                                "c"=>["subject", "author", "assigned_to", "priority", "status", "updated_on", "updated_on","pending_time"], 
                                "group_by"=>"", "project_id"=>project_id}
    end
  end

  def get_request_validity_records(params)    
    project = Project.find(params[:project_id])
    if params[:request].present?
      sub = "and ticket_tag_id ="+params[:request]
    else
      sub = ""
    end
    if params[:to1].present?
      sub = sub+" and validity >= '#{params[:from1]}' AND validity <= '#{params[:to1]}'"
    else
      sub = sub+""
    end

    if params[:employee_id].present?
      # session[:userfield]= 'emp_id'
      # session[:employee_id] = params[:employee_id]

      emp_id = UserOfficialInfo.find_by_employee_id("#{params[:employee_id]}")
      
      if emp_id == nil
        sub = sub + " and user_id = 0"
      else
        sub = sub + " and user_id = #{emp_id.user_id}"
      end
    else
      # session[:userfield]= 'user_id'
      # session[:employee_id] = params[:employee_id]
      if params[:request_user_id].to_i > 0
        sub = sub+" and user_id = #{params[:request_user_id]}"
      else
        sub = sub

      end
    end
    
    if params[:employee_id].present?
      user_var = params[:employee_id].split(',')
      multiple_emp_id = UserOfficialInfo.where(employee_id: user_var).map(&:user_id).uniq
      sub =  "and user_id IN (#{multiple_emp_id.join(', ')})" if multiple_emp_id.present?
    end
    

    tags = project.request_remainders.where("id > 0 #{sub} and validity is not NULL").order('validity')
    a  = (Date.today).to_s
    if (params[:from1]..params[:to1]).cover?(a)
      test1 =  tags.where('validity >= ?',a).order('validity Asc')
    else
      test1 =  tags.where('validity >= ?',a).order('validity Asc')
           
    end
    
      test2 =  tags.where('validity < ?',a).order('validity Asc')
      tags = test1 + test2 
      @issues = Issue.where(:id =>tags.map(&:issue_id ))
   
    @request = []
    tags.each do |rec|
      date = Date.today <= rec.validity
      user = User.find(rec.user_id)
      emp_id = user.user_official_info.employee_id rescue nil
      begin
      @request << {id:rec.issue.id, request: rec.ticket_tag.name, user_name:user.name,emp_id: emp_id, requsted_on: rec.created_at, valid_till: rec.validity, status: (date ? 'Active' : 'Expired') }
      rescue
        Rails.logger.info "Added Exception"
      end
    end
    @request.flatten
  end

  def get_current_user_request(params)
    a  = (Date.today).to_s
    project=Project.find(params[:project_id])
    current_user = User.current.id
    tags = project.request_remainders.where("user_id = #{current_user}")
    tags1 =  tags.where('validity >= ?',a).order('validity Asc')
    tags2 =  tags.where('validity < ?',a)
    tags = tags1 + tags2
    @request_issues = Issue.where(:id => tags.map(&:issue_id))
    @user_results = []
    tags.each do |rec|
      date = Date.today < rec.validity
      begin
      @user_results << {id:rec.issue.id, request: rec.ticket_tag.name, user_name:User.find(rec.user_id).name, requsted_on: rec.created_at, valid_till: rec.validity, status: (date ? 'Active' : 'Expired') }
      rescue
        p 'Added exception'
      end
    end
    @user_results.flatten
  end

  def sla_report_mail
    ActionMailer::Base.raise_delivery_errors = true
    projects = []
    Project.all.each do |project|
      projects << [project.name ,project.identifier] if project.enabled_modules.map(&:name).include?('actual_sla')
    end
    slas = []
    projects.each do |project|
      @sla_issues = []
      p '======================================master==================================================='
      get_filter_results({:page_type=>"2", :project_id=>project[1].to_s, "user_id"=>"0", 'period_type'=> "2", :from=>Date.today+1, :to=>Date.today-7, 'name' => project[1]})
      slas << {:name => project[0], :sla => @sla_issues, :total => @sla_avg }
    end
    begin
      Mailer.mail_to_sla_report(slas).deliver
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      p e.message
    end
    ActionMailer::Base.raise_delivery_errors = false
  end

  def request_remainder
    ActionMailer::Base.raise_delivery_errors = true
    alert1 = RequestRemainder.where("validity = ?", Date.today)
    alert2 = RequestRemainder.where("validity = ?", Date.today + 2.day)
    alert3 = RequestRemainder.where("validity = ?", Date.today + 7.day)
    alerts = []
    alerts << alert1
    alerts << alert2
    alerts << alert3
    alerts.each_with_index do |alert, i|
      alert.each do |mail|
        trigger_remainder(mail,i)
      end
    end
    #RequestRemainder.where("validity < ?", Date.today).delete_all
    ActionMailer::Base.raise_delivery_errors = false
  end

  def retry_remainder
    ActionMailer::Base.raise_delivery_errors = true
    alert1 = RequestRemainder.where("validity = ? and mail_status=false and retry_attempts < 4", Date.today)
    alert2 = RequestRemainder.where("validity = ? and mail_status=false and retry_attempts < 4", Date.today + 2.day)
    alert3 = RequestRemainder.where("validity = ? and mail_status=false and retry_attempts < 4", Date.today + 7.day)
    alerts = []
    alerts << alert1
    alerts << alert2
    alerts << alert3
    alerts.each_with_index do |alert, i|
      alert.each do |mail|
        trigger_remainder(mail,i)
      end
    end
    ActionMailer::Base.raise_delivery_errors = false
  end

   def trigger_remainder(mail,i)
    author = mail.issue.author_id
    tag = mail.ticket_tag_id
    new_request = RequestRemainder.where("validity > ? and user_id=? and ticket_tag_id=?",Date.today, author, tag)
    if !new_request.present?
      begin
        if i==0
          Mailer.admin_remainder(mail).deliver
        else
          Mailer.request_remainder_mail(mail).deliver
        end
        mail.update_attributes(:error_info => '', :mail_status => true,retry_attempts: 0)
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        mail.update_attributes(:error_info => e.message, :mail_status => false,retry_attempts: (mail.retry_attempts+1))
      end
    else
    end
  end

  def send_job_status_notification(status)
    project_ids =  RequestRemainder.all.map(&:project_id).uniq.compact
    # project_ids.each do |dept|
      begin
        Mailer.job_notification(status).deliver
      rescue  Exception => e
        Rails.logger.info "email delivery error = #{e}"
      end
    # end
  end

end


