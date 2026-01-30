class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.string :review_type, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :period_key, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :paused_at
      t.integer :current_step_position, default: 0

      t.timestamps
    end

    add_index :reviews, [:review_type, :period_key], unique: true
    add_index :reviews, :period_start
    add_index :reviews, :completed_at
  end
end
