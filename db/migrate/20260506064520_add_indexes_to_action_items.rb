class AddIndexesToActionItems < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :action_items, [:parent_id, :completed_at, :someday, :due_date],
              name: "index_action_items_on_filter_counts",
              algorithm: :concurrently
  end
end
