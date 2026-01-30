class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.string :title
      t.text :content
      t.references :dossier, foreign_key: true
      t.references :folder, foreign_key: true
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
