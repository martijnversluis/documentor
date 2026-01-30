class AddExpirationToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :expires_at, :date
    add_column :documents, :expiration_description, :text
  end
end
