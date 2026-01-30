class AddRecurrenceToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :recurrence, :string
  end
end
