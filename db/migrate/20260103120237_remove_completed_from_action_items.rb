class RemoveCompletedFromActionItems < ActiveRecord::Migration[8.0]
  def up
    # Migrate data: set completed_at for items marked as completed
    execute <<-SQL
      UPDATE action_items
      SET completed_at = updated_at
      WHERE completed = true AND completed_at IS NULL
    SQL

    remove_column :action_items, :completed
  end

  def down
    add_column :action_items, :completed, :boolean, default: false, null: false

    execute <<-SQL
      UPDATE action_items
      SET completed = true
      WHERE completed_at IS NOT NULL
    SQL
  end
end
