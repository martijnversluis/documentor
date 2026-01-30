class CreateDossierTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :dossier_templates do |t|
      t.string :name
      t.text :description
      t.jsonb :folders_data
      t.jsonb :action_items_data

      t.timestamps
    end
  end
end
