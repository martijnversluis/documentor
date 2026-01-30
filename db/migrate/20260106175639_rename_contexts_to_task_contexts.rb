class RenameContextsToTaskContexts < ActiveRecord::Migration[8.0]
  def change
    rename_table :contexts, :task_contexts
  end
end
