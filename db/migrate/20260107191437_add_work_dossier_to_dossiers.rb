class AddWorkDossierToDossiers < ActiveRecord::Migration[8.0]
  def change
    add_column :dossiers, :work_dossier, :boolean, default: false, null: false
  end
end
