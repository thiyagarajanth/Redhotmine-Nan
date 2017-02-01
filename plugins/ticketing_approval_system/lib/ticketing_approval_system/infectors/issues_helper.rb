module TicketingApprovalSystem
  module Infectors
    module IssuesHelper
      module ClassMethods; end

      module InstanceMethods
        def details_to_strings_with_ticketing_approval_system(details, no_html=false, options={})
          options[:only_path] = (options[:only_path] == false ? false : true)
          strings = []
          values_by_field = {}
          details.each do |detail|
            if detail.property == 'cf'
              field = detail.custom_field
              if field && field.multiple?
                values_by_field[field] ||= {:added => [], :deleted => []}
                if detail.old_value
                  values_by_field[field][:deleted] << detail.old_value
                end
                if detail.value
                  values_by_field[field][:added] << detail.value
                end
                next
              end
            end
            if detail.prop_key != 'pre_status_id'
              strings << show_detail(detail, no_html, options)
            end
          end
          values_by_field.each do |field, changes|
            detail = JournalDetail.new(:property => 'cf', :prop_key => field.id.to_s)
            detail.instance_variable_set "@custom_field", field
            if changes[:added].any?
              detail.value = changes[:added]
              strings << show_detail(detail, no_html, options)
            elsif changes[:deleted].any?
              detail.old_value = changes[:deleted]
              strings << show_detail(detail, no_html, options)
            end
          end
          strings
        end

        def show_detail_with_ticketing_approval_system(detail, no_html=false, options={})
          p no_html
          multiple = false
          case detail.property
            when 'attr'
              field = detail.prop_key.to_s.gsub(/\_id$/, "")
              label = l(("field_" + field).to_sym)
              case detail.prop_key
                when 'due_date', 'start_date'
                  value = (format_date(Time.parse(detail.value).to_date) rescue '') if detail.value
                  old_value = (format_date(Time.parse(detail.old_value).to_date) rescue '') if detail.old_value
                when 'project_id', 'status_id', 'tracker_id', 'assigned_to_id',
                    'priority_id', 'category_id', 'fixed_version_id'
                  value = find_name_by_reflection(field, detail.value)
                  old_value = find_name_by_reflection(field, detail.old_value)
                when 'estimated_hours'
                  value = "%0.02f" % detail.value.to_f unless detail.value.blank?
                  old_value = "%0.02f" % detail.old_value.to_f unless detail.old_value.blank?

                when 'parent_id'
                  label = l(:field_parent_issue)
                  value = "##{detail.value}" unless detail.value.blank?
                  old_value = "##{detail.old_value}" unless detail.old_value.blank?

                when 'is_private'
                  value = l(detail.value == "0" ? :general_text_No : :general_text_Yes) unless detail.value.blank?
                  old_value = l(detail.old_value == "0" ? :general_text_No : :general_text_Yes) unless detail.old_value.blank?
              end
            when 'cf'
              # unless no_html
              custom_field = detail.custom_field
              if custom_field
                multiple = custom_field.multiple?
                label = custom_field.name
                unless no_html
                  value = format_value(detail.value, custom_field) if detail.value
                  old_value = format_value(detail.old_value, custom_field) if detail.old_value
                end
              end
              #
            when 'attachment'
              label = l(:label_attachment)
            when 'relation'
              if detail.value && !detail.old_value
                rel_issue = Issue.visible.find_by_id(detail.value)
                value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.value}" :
                    (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
              elsif detail.old_value && !detail.value
                rel_issue = Issue.visible.find_by_id(detail.old_value)
                old_value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.old_value}" :
                    (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
              end
              relation_type = IssueRelation::TYPES[detail.prop_key]
              label = l(relation_type[:name]) if relation_type
          end
          call_hook(:helper_issues_show_detail_after_setting,
                    {:detail => detail, :label => label, :value => value, :old_value => old_value })

          label ||= detail.prop_key
          value ||= detail.value
          old_value ||= detail.old_value

          unless no_html
            label = content_tag('strong', label)
            old_value = content_tag("i", h(old_value)) if detail.old_value
            if detail.old_value && detail.value.blank? && detail.property != 'relation'
              old_value = content_tag("del", old_value)
            end
            if detail.property == 'attachment' && !value.blank? && atta = Attachment.find_by_id(detail.prop_key)
              # Link to the attachment if it has not been removed
              value = link_to_attachment(atta, :download => true, :only_path => options[:only_path])
              if options[:only_path] != false && atta.is_text?
                value += link_to(
                    image_tag('magnifier.png'),
                    :controller => 'attachments', :action => 'show',
                    :id => atta, :filename => atta.filename
                )
              end
            else
              value = content_tag("i", h(value)) if value
            end
          end

          if detail.property == 'attr' && detail.prop_key == 'description'
            s = l(:text_journal_changed_no_detail, :label => label)
            unless no_html
              diff_link = link_to 'diff',
                                  {:controller => 'journals', :action => 'diff', :id => detail.journal_id,
                                   :detail_id => detail.id, :only_path => options[:only_path]},
                                  :title => l(:label_view_diff)
              s << " (#{ diff_link })"
            end
            s.html_safe
          elsif detail.value.present?
            case detail.property
              when 'attr', 'cf'
                if detail.old_value.present?
                  l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
                elsif multiple
                  l(:text_journal_added, :label => label, :value => value).html_safe
                else
                  l(:text_journal_set_to, :label => label, :value => value).html_safe
                end
              when 'attachment', 'relation'
                l(:text_journal_added, :label => label, :value => value).html_safe
            end
          else
            l(:text_journal_deleted, :label => label, :old => old_value).html_safe
          end
        end

        def email_issue_attributes_with_ticketing_approval_system(issue, user)
          items = []
          %w(author status priority assigned_to category fixed_version request_category).each do |attribute|
            unless issue.disabled_core_fields.include?(attribute+"_id")
              if attribute == 'request_category'
                items << "#{l("field_request_category")}: #{issue.project_category ? issue.project_category.cat_name : ''}"
              else
                items << "#{l("field_#{attribute}")}: #{issue.send attribute}"
              end
            end
          end
          issue.visible_custom_field_values(user).each do |value|
             items << "#{value.custom_field.name}: #{show_value(value, false)}"
          end
          items
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
          alias_method_chain :email_issue_attributes, :ticketing_approval_system
          alias_method_chain :details_to_strings, :ticketing_approval_system
          alias_method_chain :show_detail, :ticketing_approval_system

        end
      end
    end
  end
end