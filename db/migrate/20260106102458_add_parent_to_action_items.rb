class AddParentToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :action_items, :parent, null: true, foreign_key: { to_table: :action_items }
  end
end
