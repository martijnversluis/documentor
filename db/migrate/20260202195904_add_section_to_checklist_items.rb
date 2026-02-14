class AddSectionToChecklistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :checklist_items, :section, :string
  end
end
