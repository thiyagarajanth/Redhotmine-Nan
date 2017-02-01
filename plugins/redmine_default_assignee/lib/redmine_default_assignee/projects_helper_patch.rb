module RedmineDefaultAssignee
 module ProjectsHelperPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method_chain :project_settings_tabs, :default_assignee
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def project_settings_tabs_with_default_assignee
          tabs = project_settings_tabs_without_default_assignee
          return tabs unless @project.module_enabled?('default_assign')
          if User.current.allowed_to?(:default_assignee_setup, @project) || User.current.admin?
            @default_assignees = DefaultAssigneeSetup.where(:project_id=>@project.id)
            tabs << {:name => 'default_assignee',:action => :index, :partial => 'default_assignee_setup/index', :label => :lable_default_assignee}
          end
          tabs
        end
      end
 end
  end


