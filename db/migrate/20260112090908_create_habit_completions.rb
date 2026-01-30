class CreateHabitCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :habit_completions do |t|
      t.references :habit, null: false, foreign_key: true
      t.date :completed_on, null: false
      t.text :notes

      t.timestamps
    end

    add_index :habit_completions, [:habit_id, :completed_on], unique: true
    add_index :habit_completions, :completed_on
  end
end
