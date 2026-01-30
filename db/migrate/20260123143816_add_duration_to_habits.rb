class AddDurationToHabits < ActiveRecord::Migration[8.0]
  def change
    add_column :habits, :duration_seconds, :integer
  end
end
