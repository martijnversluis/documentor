class AddEstimatedMinutesToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :estimated_minutes, :integer
  end
end
