class ChangeTargetCountNullableOnHabits < ActiveRecord::Migration[8.0]
  def change
    change_column_null :habits, :target_count, true
  end
end
