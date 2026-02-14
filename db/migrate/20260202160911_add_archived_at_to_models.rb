class AddArchivedAtToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :habits, :archived_at, :datetime
    add_column :checklists, :archived_at, :datetime
    add_column :review_templates, :archived_at, :datetime
  end
end
