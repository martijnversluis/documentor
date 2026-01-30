class AddArchivedAtToDossiers < ActiveRecord::Migration[8.0]
  def change
    add_column :dossiers, :archived_at, :datetime
    add_index :dossiers, :archived_at
  end
end
