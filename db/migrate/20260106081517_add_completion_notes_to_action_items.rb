class AddCompletionNotesToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :action_items, :completion_notes, :text
  end
end
