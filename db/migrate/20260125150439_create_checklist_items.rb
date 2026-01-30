class CreateChecklistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :checklist_items do |t|
      t.references :checklist, null: false, foreign_key: true
      t.text :description
      t.integer :position
      t.string :context
      t.integer :estimated_minutes

      t.timestamps
    end
  end
end
