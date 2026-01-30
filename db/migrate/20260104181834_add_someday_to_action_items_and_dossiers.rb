class AddSomedayToActionItemsAndDossiers < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :someday, :boolean, default: false, null: false
    add_column :dossiers, :someday, :boolean, default: false, null: false
  end
end
