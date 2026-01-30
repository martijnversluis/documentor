class AddRemarksToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :remarks, :text
  end
end
