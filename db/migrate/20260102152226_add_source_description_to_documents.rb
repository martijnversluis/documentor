class AddSourceDescriptionToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :source_description, :text
  end
end
