#*******************************************************************************
# clipboard_image_paste Redmine plugin.
#
# Hooks.
#
# Authors:
# - Richard Pecl
#
# Terms of use:
# - GNU GENERAL PUBLIC LICENSE Version 2
#*******************************************************************************

module EmployeeInfo
  class Hooks  < Redmine::Hook::ViewListener

    # Add stylesheets and javascripts links to all pages
    # (there's no way to add them on specific existing page)
    render_on :view_users_form,
      :partial => "official_info/form"
    render_on :view_layouts_base_html_head,
              :partial => "members/header_render_js"
    # Render image paste form on every page,
    # javascript allows the form to show on issues, news, files, documents, wiki
    # render_on :view_layouts_base_body_bottom,
    #   :partial => "clipboard_image_paste/add_form"

  end # class
end # module
