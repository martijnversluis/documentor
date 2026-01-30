class CreateActionItemDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :action_item_documents do |t|
      t.references :action_item, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true

      t.timestamps
    end

    add_index :action_item_documents, [:action_item_id, :document_id], unique: true
  end
end
