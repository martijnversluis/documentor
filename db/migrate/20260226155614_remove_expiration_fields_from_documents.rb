class RemoveExpirationFieldsFromDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_column :documents, :expires_at, :date
    remove_column :documents, :expiration_description, :text
  end
end
