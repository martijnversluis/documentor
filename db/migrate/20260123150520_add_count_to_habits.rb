class AddCountToHabits < ActiveRecord::Migration[8.0]
  def change
    add_column :habits, :target_count, :integer, default: 1, null: false
    add_column :habit_completions, :count, :integer, default: 1, null: false
  end
end
