class AddDueTimeToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :due_time, :time
  end
end
