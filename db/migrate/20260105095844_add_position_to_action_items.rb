class AddPositionToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :position, :integer
  end
end
