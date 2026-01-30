class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :name
      t.references :dossier, foreign_key: true
      t.references :folder, foreign_key: true
      t.text :content_text
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
