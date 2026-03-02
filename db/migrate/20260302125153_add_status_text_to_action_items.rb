class AddStatusTextToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :status_text, :string
  end
end
