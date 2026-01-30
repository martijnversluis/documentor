class AddInboxSupport < ActiveRecord::Migration[8.0]
  def change
    change_column_null :action_items, :dossier_id, true
  end
end
