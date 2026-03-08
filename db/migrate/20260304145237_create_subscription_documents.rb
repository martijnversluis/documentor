class CreateSubscriptionDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_documents do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true

      t.timestamps
    end

    add_index :subscription_documents, [:subscription_id, :document_id], unique: true
  end
end
