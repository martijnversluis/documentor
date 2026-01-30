class AddContextToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :context, :string
  end
end
