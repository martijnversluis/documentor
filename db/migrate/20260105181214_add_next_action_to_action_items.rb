class AddNextActionToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :next_action, :boolean, default: false, null: false
  end
end
