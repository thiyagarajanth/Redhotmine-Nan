# Redmine - project management software
# Copyright (C) 2006-2015  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class BoardsController < ApplicationController
  default_search_scope :messages
  before_filter :find_project_by_project_id, :find_board_if_available, :authorize
  accept_rss_auth :index, :show

  helper :sort
  include SortHelper
  helper :watchers

  def index
    @boards = @project.boards.includes(:project, :last_message => :author).all
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end

  def show
    respond_to do |format|
      format.html {
        sort_init 'updated_on', 'desc'
        sort_update 'created_on' => "#{Message.table_name}.created_on",
                    'replies' => "#{Message.table_name}.replies_count",
                    'updated_on' => "COALESCE(last_replies_messages.created_on, #{Message.table_name}.created_on)"

        @topic_count = @board.topics.count
        @topic_pages = Paginator.new @topic_count, per_page_option, params['page']
        @topics =  @board.topics.
          reorder("#{Message.table_name}.sticky DESC").
          includes(:last_reply).
          limit(@topic_pages.per_page).
          offset(@topic_pages.offset).
          order(sort_clause).
          preload(:author, {:last_reply => :author}).
          all
        @message = Message.new(:board => @board)
        render :action => 'show', :layout => !request.xhr?
      }
      format.atom {
        @messages = @board.messages.
          reorder('created_on DESC').
          includes(:author, :board).
          limit(Setting.feeds_limit.to_i).
          all
        render_feed(@messages, :title => "#{@project}: #{@board}")
      }
    end
  end

  def new
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
  end

  def create
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
    if @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @board.safe_attributes = params[:board]
    if @board.save
      redirect_to_settings_in_projects
    else
      render :action => 'edit'
    end
  end

  def destroy
    @board.destroy
    redirect_to_settings_in_projects
  end

private
  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'boards')
  end

  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
