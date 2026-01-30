class AddWaitingForToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :action_items, :waiting_for_party, foreign_key: { to_table: :parties }, null: true
    add_column :action_items, :waiting_for_description, :string
  end
end
