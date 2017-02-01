class AddColumnToRespondSla < ActiveRecord::Migration
  def change
    add_column :response_slas, :ticket_closing, :integer
  end

end