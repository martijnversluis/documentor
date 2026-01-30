class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.string :name
      t.references :dossier, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
