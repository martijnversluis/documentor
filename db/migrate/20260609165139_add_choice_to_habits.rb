class AddChoiceToHabits < ActiveRecord::Migration[8.0]
  def change
    add_column :habits, :choice_options, :text
    add_column :habit_completions, :choice_value, :string
  end
end
